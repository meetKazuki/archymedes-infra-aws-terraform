data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

##############################################################
# ECR repository
##############################################################

resource "aws_ecr_repository" "this" {
  name                 = local.repository_name_parsed
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "AllowOwnerPushPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.effective_principals
    }

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
