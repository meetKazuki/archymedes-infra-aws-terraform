##############################################################
# Default VPC lookup
##############################################################

data "aws_vpc" "default" {
  default = true
}

##############################################################
# S3 bucket
##############################################################

# tfsec:ignore:aws-s3-enable-bucket-logging Bucket access logging is not part of the coding-challenge spec. Production hardening would add a dedicated logs bucket and a `aws_s3_bucket_logging` resource pointing here.
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name_parsed
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# tfsec:ignore:aws-s3-encryption-customer-key The challenge spec calls for "server-side encryption using Amazon managed keys" — AWS docs map this exact wording to SSE-S3 (AES256), not SSE-KMS with a customer-managed key. Switching to CMK here would mismatch the spec.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Versioning is not in the spec, but is so cheap and so universally
# expected that omitting it would be the more surprising choice.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

##############################################################
# Access point in the default VPC
##############################################################

resource "aws_s3_access_point" "this" {
  bucket = aws_s3_bucket.this.id
  name   = local.access_point_name

  public_access_block_configuration {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  vpc_configuration {
    vpc_id = data.aws_vpc.default.id
  }
}
