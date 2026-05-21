variable "aws_region" {
  type        = string
  description = "Deployment region."
}

variable "app_name" {
  type        = string
  description = "Application name, used in default tags."
  default     = "archymedes"
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "prod"
}

variable "ecr_repo_name" {
  type        = string
  description = "Name for the ECR repository."
}

variable "allowed_principal_arns" {
  type        = list(string)
  description = "IAM principal ARNs allowed to push/pull. Empty list = current caller."
  default     = []
}

variable "ecr_lifecycle_keep_last" {
  type        = number
  description = "Keep the last N ECR images. 0 disables the lifecycle policy."
  default     = 30
}

variable "s3_bucket_name" {
  type        = string
  description = "Name for the S3 bucket. Must be globally unique."
}
