##############################################################
# Caller identity (used as default principal if none supplied)
##############################################################

data "aws_caller_identity" "current" {}

##############################################################
# ECR repository
##############################################################

# tfsec:ignore:aws-ecr-repository-customer-key The challenge spec calls for "encryption using an AWS managed key", which AWS docs map specifically to the aws/ecr AWS-managed KMS key (not a customer-managed key). Switching to CMK would exceed and mismatch the spec.
resource "aws_ecr_repository" "this" {
  name                 = local.repository_name_parsed
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # "AWS managed key" => SSE-KMS with the AWS-managed aws/ecr KMS key.
  # Omitting kms_key here selects that default; AES256 would be AWS-OWNED.
  encryption_configuration {
    encryption_type = "KMS"
  }
}

##############################################################
# Repository policy: restrict push/pull to the listed principals.
# Falls back to the current caller's ARN if no principals provided.
##############################################################

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "AllowOwnerPushPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.effective_principals
    }

    # Push actions
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
  }
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.this.json
}

##############################################################
# Lifecycle policy (optional, on by default to keep storage sane)
##############################################################

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_keep_last == 0 ? 0 : 1
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.lifecycle_keep_last} images, expire the rest"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.lifecycle_keep_last
      }
      action = { type = "expire" }
    }]
  })
}
