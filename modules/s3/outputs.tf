output "bucket" {
  description = "S3 bucket details"
  value = {
    name = aws_s3_bucket.this.id
    arn  = aws_s3_bucket.this.arn
  }
}

output "access_point" {
  description = "S3 access point details"
  value = {
    name  = aws_s3_access_point.this.name
    arn   = aws_s3_access_point.this.arn
    alias = aws_s3_access_point.this.alias
  }
}

output "vpc_id" {
  description = "ID of the default VPC the access point is bound to."
  value       = data.aws_vpc.default.id
}
