# Module: `ecr`

Provisions a private Amazon Elastic Container Registry repository hardened
to the coding-challenge spec.

## What it creates

- `aws_ecr_repository` — private, with `IMMUTABLE` tag policy and scan-on-push enabled.
- `aws_ecr_repository_policy` — restricts push and pull actions to the
  caller (or to the explicit list of principals you pass in).
- `aws_ecr_lifecycle_policy` — keeps the last *N* images (default 30),
  disabled by setting `lifecycle_keep_last = 0`.

## Encryption

Uses `encryption_type = "KMS"` with no `kms_key` set, which selects the
AWS-managed `aws/ecr` KMS key. AES256 was rejected here because AWS docs
classify it as an "AWS-owned" key, not an "AWS-managed" key.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `repository_name` | `string` | _required_ | Repo name. Lowercased and spaces replaced with `-`. |
| `allowed_principal_arns` | `list(string)` | `[]` | IAM principal ARNs allowed to push/pull. Empty list = current caller. |
| `lifecycle_keep_last` | `number` | `30` | Keep last N images. `0` disables lifecycle policy. |

## Outputs

| Name | Description |
|------|-------------|
| `repository.name` | Repository name |
| `repository.arn`  | Repository ARN |
| `repository.url`  | Registry URL (use for `docker tag`/`docker push`) |
| `effective_principals` | The principals actually granted push/pull |

## Notes

- `ecr:GetAuthorizationToken` is intentionally *not* in the repository
  policy. It is an account-level action and must be granted via an IAM
  policy on the principal, not on the repo.
- Image scan findings can be retrieved with
  `aws ecr describe-image-scan-findings`.
