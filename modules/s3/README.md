# Module: `s3`

Provisions a private Amazon S3 bucket with an access point bound to the default VPC.

## What it creates

- `aws_s3_bucket` — the bucket itself.
- `aws_s3_bucket_public_access_block` — all four "block public" flags on.
- `aws_s3_bucket_server_side_encryption_configuration` — SSE-S3 (AES256).
- `aws_s3_bucket_ownership_controls` — `BucketOwnerEnforced` (ACLs off).
- `aws_s3_bucket_versioning` — `Enabled`. Not in the spec; added because it's cheap, universally expected,
and protects against accidental overwrites during testing.
- `aws_s3_access_point` — bound to the default VPC, public access blocked.

## Encryption

Uses `AES256` (SSE-S3) — what AWS docs call "Server-side encryption with Amazon S3 managed keys." This matches
the challenge wording "Amazon managed keys." SSE-KMS with `aws/s3` is the alternative interpretation but reads
as "AWS managed key" in AWS docs (which is the ECR wording).

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name` | `string` | _required_ | Globally-unique bucket name. |
| `access_point_name_suffix` | `string` | `"ap"` | Suffix on the access point name. Bucket portion is truncated if needed to fit S3's 50-char access-point name limit. |

## Outputs

| Name | Description |
|------|-------------|
| `bucket.name`, `bucket.arn` | Bucket identifiers |
| `access_point.name/arn/alias` | Access point identifiers |
| `vpc_id` | The default VPC the access point is bound to |

## Notes

- The default VPC must exist in the region. AWS accounts created after Dec 2013 get a default VPC per region automatically,
but some accounts have had theirs deleted. Plan will fail with "no matching VPC" if so.
- This module does not attach an access point policy. Add one if you want to delegate via the access point ARN (e.g. for cross-account).
