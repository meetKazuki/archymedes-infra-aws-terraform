variable "repository_name" {
  type        = string
  description = "Name of the ECR repository. Lowercased and spaces replaced with '-'."
}

variable "allowed_principal_arns" {
  type        = list(string)
  description = <<-EOT
    IAM principal ARNs allowed to push and pull images.
    If empty, defaults to the current Terraform caller's ARN
    (sts:GetCallerIdentity), which satisfies the 'only your user id' requirement
    when running locally as that user.
  EOT
  default     = []
}

variable "lifecycle_keep_last" {
  type        = number
  description = "How many most-recent images to keep. Set to 0 to disable the lifecycle policy entirely."
  default     = 30
}
