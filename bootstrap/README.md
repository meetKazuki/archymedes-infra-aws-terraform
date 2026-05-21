# Bootstrap

One-time setup that creates everything the main pipelines depend on:

1. **Terraform state bucket** — versioned, encrypted, public access blocked.
2. **GitHub OIDC identity provider** in AWS IAM.
3. **IAM role** that GitHub Actions assumes via OIDC. Scoped to manage the resources the modules create plus
the state bucket.

State for this config is intentionally **local** — there is no remote backend, because this config *creates*
the bucket the remote backend would use. Apply once, then back up `terraform.tfstate` somewhere safe
(e.g. encrypted in a password manager). Do not commit it.

## Apply

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — set state_bucket_name, github_org, github_repo

terraform init
terraform apply
```

After apply, copy the outputs into GitHub repository secrets:

| Output              | GitHub secret |
|---------------------|---------------|
| `state_bucket_name` | `AWS_TF_STATE_BUCKET` |
| `gha_role_arn`      | `AWS_DEPLOY_ROLE_ARN` |
| `aws_region`        | `AWS_REGION` |

Then push the repo. The plan / apply / destroy workflows will use these secrets to authenticate via OIDC — no
long-lived AWS keys in GitHub.

## Cleanup

```bash
# First, run the Terraform Destroy workflow to remove the application resources.
# Then, locally:
terraform destroy
```

The state bucket has versioning enabled, so `terraform destroy` will need to empty it first if it contains any state
objects.
