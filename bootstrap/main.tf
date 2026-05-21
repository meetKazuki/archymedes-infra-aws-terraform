data "aws_caller_identity" "current" {}

##############################################################
# Terraform state bucket
##############################################################

resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

##############################################################
# IAM role assumed by GitHub Actions via OIDC
##############################################################

data "aws_iam_policy_document" "gha_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for branch in var.github_branches :
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
      ]
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid    = "EcrManageRepos"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:GetRepositoryPolicy",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
      "ecr:PutImageTagMutability",
      "ecr:PutImageScanningConfiguration",
      "ecr:GetLifecyclePolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
    ]
    resources = [
      "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.resource_name_prefix}-*",
    ]
  }

  statement {
    sid    = "S3ManageWorkloadBuckets"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketAcl",
      "s3:PutBucketAcl",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "s3:PutBucketOwnershipControls",
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetReplicationConfiguration",
    ]
    resources = [
      "arn:aws:s3:::${var.resource_name_prefix}-*",
    ]
  }

  # --- S3: access points ---------------------------------------------------
  statement {
    sid    = "S3ManageWorkloadAccessPoints"
    effect = "Allow"
    actions = [
      "s3:GetAccessPoint",
      "s3:CreateAccessPoint",
      "s3:DeleteAccessPoint",
      "s3:GetAccessPointPolicy",
      "s3:PutAccessPointPolicy",
      "s3:DeleteAccessPointPolicy",
    ]
    resources = [
      "arn:aws:s3:*:${data.aws_caller_identity.current.account_id}:accesspoint/${var.resource_name_prefix}-*",
    ]
  }

  statement {
    sid       = "S3ListAccessPointsAccountWide"
    effect    = "Allow"
    actions   = ["s3:ListAccessPoints"]
    resources = ["*"]
  }

  statement {
    sid    = "Ec2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeAccountAttributes",
    ]
    resources = ["*"]
  }

  # --- STS -----------------------------------------------------------------
  statement {
    sid       = "StsGetCallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]
    resources = [aws_s3_bucket.tfstate.arn]
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.tfstate.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "gha" {
  name   = "archymedes-deployer"
  role   = aws_iam_role.gha.id
  policy = data.aws_iam_policy_document.gha_permissions.json
}
