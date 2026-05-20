locals {
  repository_name_parsed = replace(lower(var.repository_name), " ", "-")

  effective_principals = length(var.allowed_principal_arns) > 0 ? var.allowed_principal_arns : [data.aws_caller_identity.current.arn]
}
