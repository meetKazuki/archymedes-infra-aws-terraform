module "ecr" {
  source = "../../modules/ecr"

  repository_name        = var.ecr_repo_name
  allowed_principal_arns = var.allowed_principal_arns
  lifecycle_keep_last    = 0
}
