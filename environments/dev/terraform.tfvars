aws_region  = "us-east-1"
app_name    = "archymedes-aws-tf"
environment = "dev"

ecr_repo_name          = "archymedes-app"
allowed_principal_arns = ["arn:aws:iam::123456789012:user/your-iam-user"]

s3_bucket_name = "archymedes-data-bucket-12345"
