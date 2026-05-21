data "aws_vpc" "default" {
  default = true
}

##############################################################
# S3 bucket
##############################################################

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
