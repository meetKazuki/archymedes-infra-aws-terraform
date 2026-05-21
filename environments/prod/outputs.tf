output "ecr_repository" {
  description = "ECR repository details"
  value       = module.ecr.repository
}

output "s3_bucket" {
  description = "S3 bucket details"
  value       = module.s3.bucket
}

output "s3_access_point" {
  description = "S3 access point details"
  value       = module.s3.access_point
}
