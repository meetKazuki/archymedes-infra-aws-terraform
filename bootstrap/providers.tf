provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      AppName     = "archymedes"
      Environment = "bootstrap"
      ManagedBy   = "Terraform"
      Repo        = "archymedes"
    }
  }
}
