output "state_bucket_name" {
  description = "Set this as the AWS_TF_STATE_BUCKET secret in the GitHub repo."
  value       = aws_s3_bucket.tfstate.id
}

output "gha_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN secret in the GitHub repo."
  value       = aws_iam_role.gha.arn
}

output "aws_region" {
  value = var.aws_region
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
