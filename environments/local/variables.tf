variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "app_name" {
  type    = string
  default = "archymedes"
}

variable "environment" {
  type    = string
  default = "local"
}

variable "ecr_repo_name" {
  type    = string
  default = "archymedes-app"
}

variable "allowed_principal_arns" {
  type    = list(string)
  default = ["arn:aws:iam::000000000000:root"]
}
