variable "aws_region" {
  type        = string
  description = "Region for the state bucket."
  default     = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally-unique name for the Terraform state bucket. Used by both environments."
}

variable "github_org" {
  type        = string
  description = "GitHub org or username that owns the repo."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (without org)."
}

variable "github_branches" {
  type        = list(string)
  description = "Branches whose workflow runs may assume the role. Use ['*'] for all branches."
  default     = ["main"]
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role assumed by GitHub Actions."
  default     = "archymedes-gha-deployer"
}

variable "resource_name_prefix" {
  type        = string
  description = "Prefix that every workload resource name must start with. Used to scope the deployer role's IAM permissions to only resources under this prefix."
  default     = "archymedes"
}
