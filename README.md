# Archymedes DevOps

Terraform + GitHub Actions pipeline that provisions a hardened private ECR repository and a hardened S3 bucket with a VPC-bound access point.
Built for the DevOps Engineer coding challenge.

```
.
├── bootstrap/                 # one-time: state bucket, OIDC provider, deployer role
├── modules/
│   ├── ecr/                   # private repo, immutable tags, scan on push, KMS, scoped policy
│   └── s3/                    # private bucket, SSE-S3, ACLs off, VPC access point
├── environments/
│   ├── prod/                  # the main environment the pipelines deploy
│   └── local/                 # LocalStack target for offline smoke-tests
├── .github/workflows/
│   ├── tf-validate.yml        # PR-time: fmt + validate + tflint + tfsec
│   ├── tf-plan.yml            # manual: terraform plan, uploads artifact
│   ├── tf-apply.yml           # manual: downloads plan, applies
│   └── tf-destroy.yml         # manual: tears everything down
├── docs/
│   └── ecr-push-pull-demo.md  # how to demonstrate push/pull on the repo
├── docker-compose.yml         # LocalStack
└── Makefile                   # fmt / validate / lint / sec / local-up
```

## Design summary

| Spec line | How it's implemented |
|---|---|
| ECR private | `aws_ecr_repository` (private by default) |
| ECR tag immutability | `image_tag_mutability = "IMMUTABLE"` |
| ECR scan on push | `image_scanning_configuration.scan_on_push = true` |
| ECR encryption — AWS managed key | `encryption_type = "KMS"` with no `kms_key`, which selects `aws/ecr` |
| ECR push/pull restricted to your user | `aws_ecr_repository_policy` granting only the listed principal ARNs; defaults to the current caller |
| S3 block all public access | `aws_s3_bucket_public_access_block` with all four flags `true` |
| S3 SSE with Amazon managed keys | `AES256` (SSE-S3) |
| S3 ACLs disabled | `aws_s3_bucket_ownership_controls` with `BucketOwnerEnforced` |
| S3 access point in default VPC | `aws_s3_access_point` with `vpc_configuration.vpc_id = data.aws_vpc.default.id` |
| GH Actions in YAML | `.github/workflows/*.yml` |
| Pass values at run time | `workflow_dispatch.inputs.*` → `TF_VAR_*` env vars |
| Maintain Terraform state | S3 backend, `use_lockfile = true` (Terraform 1.10+ native locking) |
| Allow deletion when done | `tf-destroy.yml` with explicit `confirm: "destroy"` input |

## Encryption — why KMS for ECR and AES256 for S3

The two pipelines use *different* terminology in the spec, and AWS has precise meanings for these:

- "AWS-owned key" — not visible to you, fully managed by AWS. AES256 on ECR falls in this bucket.
- "AWS managed key" — KMS key like `aws/ecr` or `aws/s3`, visible in your KMS console.
- "Amazon S3 managed key" — SSE-S3 specifically. AWS uses this exact phrasing in the S3 docs.

ECR says **"AWS managed key"** → KMS with `aws/ecr`. S3 says **"Amazon managed keys"** → SSE-S3 / AES256.

## Authentication — OIDC, not static keys

GitHub Actions assumes the `archymedes-gha-deployer` IAM role via GitHub's OIDC identity provider. There are **no long-lived AWS access
keys** stored in GitHub. The `bootstrap/` Terraform config creates the OIDC provider, the role, and a scoped permission policy.

The workflows request a short-lived OIDC token via `permissions: id-token: write` and exchange it for AWS credentials with
`aws-actions/configure-aws-credentials@v4`.

## Getting started

### 1. Prerequisites

- Terraform `>= 1.10` (for S3 native state locking)
- AWS CLI v2
- Docker (for the LocalStack and ECR demos)
- An AWS account where you can create IAM resources

### 2. Bootstrap (one time, per account)

This creates the state bucket and the GitHub Actions deployer role.

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# edit: set state_bucket_name (must be globally unique), github_org, github_repo

terraform init
terraform apply
```

Take the three outputs and save them as GitHub repo secrets:

| Output | Secret name |
|---|---|
| `state_bucket_name` | `AWS_TF_STATE_BUCKET` |
| `gha_role_arn`      | `AWS_DEPLOY_ROLE_ARN` |
| `aws_region`        | `AWS_REGION` |

Back up `bootstrap/terraform.tfstate` outside the repo (don't commit
it — it contains the OIDC and role ARNs).

### 3. Run the pipelines

Push the repo to GitHub. Then in the **Actions** tab:

1. **Terraform Plan** — run with the inputs documented below. Note the *run ID* (in the URL of the run page).
2. **Terraform Apply** — run with the same `env` and `aws_region`, and the plan's *run ID*. Apply downloads the plan artifact from that run.
3. **Terraform Destroy** — when finished, run with the same inputs. Type `destroy` into the `confirm` input or the job won't start.

### 4. Demonstrate ECR push/pull

See [`docs/ecr-push-pull-demo.md`](docs/ecr-push-pull-demo.md).

## Pipeline inputs (run-time parameters)

### `Terraform Plan`

| Input | Required | Default | Notes |
|---|---|---|---|
| `env` | ✅ | `dev` | Subdirectory under `environments/`. |
| `aws_region` | | `us-east-1` | Must match the bootstrap region. |
| `ecr_repo_name` | | `archymedes-app` | Will be lowercased and `-`-joined. |
| `s3_bucket_name` | ✅ | _none_ | **Globally unique** — pick something like `archymedes-dev-<your-handle>-<short-random>`. |
| `allowed_principal_arns` | | `[]` | JSON list. Empty list = the GHA OIDC role itself. |

### `Terraform Apply`

| Input | Required | Default | Notes |
|---|---|---|---|
| `env` | ✅ | `dev` | Must match the plan run. |
| `aws_region` | ✅ | `us-east-1` | Must match the plan run. |
| `plan_run_id` | ✅ | _none_ | The numeric Run ID of the Plan workflow run whose artifact to download. |

### `Terraform Destroy`

Same inputs as Plan, plus `confirm` which must equal `destroy`.

## Testing strategy

### Layer 1 — Pure-static, no cloud (fastest, free)

Catches the majority of bugs in seconds, runs anywhere.

```bash
make all     # fmt-check + validate + tflint + tfsec
```

This is also what `tf-validate.yml` runs on every PR.

### Layer 2 — LocalStack (offline integration)

Honest scope: LocalStack Community covers `S3` (bucket + encryption + ownership + public-access-block) and validates ECR / IAM API surface,
but **S3 access points and `docker push` to ECR require LocalStack Pro**. `environments/local/` instantiates only the ECR module for that
reason.

```bash
make local-up        # start LocalStack on localhost:4566
make local-apply     # terraform apply against LocalStack
make local-destroy
make local-down
```

### Layer 3 — Real AWS

The full verification. After bootstrap is applied:

1. **Plan** via the workflow with realistic inputs. Inspect the uploaded `plan-summary.txt` artifact.
2. **Apply** via the workflow, referencing the plan's run ID.
3. **Verify ECR**:
   - `aws ecr describe-repositories --repository-names archymedes-app`
   - Run through [`docs/ecr-push-pull-demo.md`](docs/ecr-push-pull-demo.md).
4. **Verify S3**:
   - `aws s3api get-bucket-encryption --bucket <name>`
   - `aws s3api get-public-access-block --bucket <name>`
   - `aws s3control get-access-point --account-id <acct> --name <ap-name>`
   - Object via access point ARN (from inside the default VPC, e.g. from an EC2 instance there):
     `aws s3api put-object --bucket arn:aws:s3:us-east-1:<acct>:accesspoint/<ap-name> --key hello.txt --body hello.txt`
5. **Verify scan on push** — push the image, then `aws ecr describe-image-scan-findings`.
6. **Destroy** via the workflow.

## Assumptions

- The target AWS account still has the **default VPC** in the chosen region. Some hardened accounts have deleted it. The plan will fail
  with "no matching VPC" if so.
- The bootstrap is run by a principal with permissions to create IAM OIDC providers, IAM roles, and S3 buckets. In most setups that means
  an admin-level user; the bootstrap output produces the *scoped* role the workflows then use.
- Region for the state bucket and for the workload are the same. If you want them split, change `region` passed to `terraform init`
  separately from `var.aws_region`.
- The S3 access point name is the bucket name plus `-ap`, truncated to fit S3's 50-character access-point name limit.
- `image_tag_mutability = IMMUTABLE` means once a tag is pushed it can't be moved. Reusing tags (e.g. `:latest`) will fail.
- ECR encryption uses the AWS-managed `aws/ecr` KMS key. Switching to a customer-managed key is a one-line change in `modules/ecr/main.tf`
  but is not in scope.
- The terraform state bucket created by bootstrap is *not* itself managed by the pipelines. It needs to be deleted manually after
  running `terraform destroy` on bootstrap, to break the state-bucket-stores-its-own-state chicken-and-egg.

## Repo conventions

- `terraform fmt` is enforced via `tf-validate.yml`.
- `tflint` runs with the `terraform` plugin preset.
- `tfsec` runs with `soft_fail: false` — a finding fails the PR.
- Module READMEs document Inputs/Outputs. Run `terraform-docs` if you add a variable.
- `CODEOWNERS` requires review from @meetKazuki on workflow and module changes.
