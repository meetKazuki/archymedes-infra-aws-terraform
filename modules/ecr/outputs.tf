output "repository" {
  description = "ECR repository details"
  value = {
    name = aws_ecr_repository.this.name
    arn  = aws_ecr_repository.this.arn
    url  = aws_ecr_repository.this.repository_url
  }
}

output "effective_principals" {
  description = "The IAM principal ARNs that were granted push/pull on this repo."
  value       = local.effective_principals
}
