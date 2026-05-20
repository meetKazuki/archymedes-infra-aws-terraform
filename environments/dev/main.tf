module "ecr" {
  source = "../../modules/ecr"

  repository_name        = var.ecr_repo_name
  allowed_principal_arns = var.allowed_principal_arns
  lifecycle_keep_last    = var.ecr_lifecycle_keep_last
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = var.s3_bucket_name
}
