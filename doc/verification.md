```sh
export AWS_REGION=us-east-1
export ACCOUNT=767558959217
export REPO=archymedes-app
export BUCKET=archymedes-prod-bucket-ef9b
```

- `aws ecr describe-repositories --repository-names $REPO --query 'repositories[0].{name:repositoryName,immutable:imageTagMutability,scan:imageScanningConfiguration.scanOnPush,enc:encryptionConfiguration.encryptionType}'` returns

```json
{
  "name": "archymedes-app",
  "immutable": "IMMUTABLE",
  "scan": true,
  "enc": "KMS"
}
```

- `aws ecr get-repository-policy --repository-name $REPO --query policyText --output text | jq .` returns

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOwnerPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::767558959217:role/archymedes-gha-deployer"
      },
      "Action": [
        "ecr:UploadLayerPart",
        "ecr:PutImage",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
```

- `aws s3api get-bucket-encryption --bucket $BUCKET` returns

```json
{
  "ServerSideEncryptionConfiguration": {
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": false
      }
    ]
  }
}
```

- `aws s3api get-public-access-block --bucket $BUCKET` returns

```json
{
  "PublicAccessBlockConfiguration": {
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }
}
```

- `aws s3api get-bucket-ownership-controls --bucket $BUCKET` returns

```json
{
  "OwnershipControls": {
    "Rules": [
      {
        "ObjectOwnership": "BucketOwnerEnforced"
      }
    ]
  }
}
```

- `aws s3api get-bucket-versioning --bucket $BUCKET` returns

```json
{
  "Status": "Enabled"
}
```

- `aws s3control list-access-points --account-id $ACCOUNT --bucket $BUCKET` returns

```json
{
  "AccessPointList": [
    {
      "Name": "archymedes-prod-bucket-ef9b-ap",
      "NetworkOrigin": "VPC",
      "VpcConfiguration": {
        "VpcId": "vpc-0e2d1a326d916b123"
      },
      "Bucket": "archymedes-prod-bucket-ef9b",
      "AccessPointArn": "arn:aws:s3:us-east-1:767558959217:accesspoint/archymedes-prod-bucket-ef9b-ap",
      "Alias": "archymedes-prod-buck-fdjdw5iw54kow87dfacqq95yrd7cause1b-s3alias",
      "BucketAccountId": "767558959217"
    }
  ]
}
```
