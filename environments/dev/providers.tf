terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47"
    }
  }

  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      AppName     = var.app_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repo        = "archymedes"
    }
  }
}
