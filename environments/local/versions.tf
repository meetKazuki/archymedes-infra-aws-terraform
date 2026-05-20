terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47"
    }
  }

  # Local backend for LocalStack runs — no remote state.
  backend "local" {}
}
