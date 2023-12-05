provider "aws" {
  region = var.region
}

locals {
  iam_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "S3Access",
        Effect = "Allow",
        Action = ["s3:*"],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"
        ]
      },
      {
        Sid      = "S3ListBucket",
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}"
      },
      {
        Sid      = "KMSListKeys",
        Effect   = "Allow",
        Action   = "kms:ListKeys",
        Resource = "*"
      },
      {
        Sid    = "KMSRead",
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = aws_kms_key.my_key.arn
      },
      {
        Sid    = "DynamoDBAccess",
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Resource = aws_dynamodb_table.my_dynamodb_table.arn
      }
    ]
  })
}

#AWS Key config
resource "aws_kms_key" "my_key" {
  description             = "Encryption key for TF Remote State"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "a" {
  name          = "alias/my_key_alias"
  target_key_id = aws_kms_key.my_key.key_id
}

##
## AWS Bucket config
##

#
# Log bucket
#

resource "aws_s3_bucket" "my_log_bucket" {
  bucket = var.log_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.my_log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_ownership]

  bucket = aws_s3_bucket.my_log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket = aws_s3_bucket.my_bucket.id

  target_bucket = aws_s3_bucket.my_log_bucket.id
  target_prefix = "log/"
}

#
# State bucket
#

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.state_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "state_bucket_ownership" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "state_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.state_bucket_ownership]

  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.my_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
##
## DyanomoDB Config
##

resource "aws_dynamodb_table" "my_dynamodb_table" {
  name           = var.table_name
  read_capacity  = 3
  write_capacity = 1
  hash_key       = "LockID"
  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}

##
## IAM Config
##

resource "aws_iam_role" "role" {
  path = "/terraform-remote-state/"

  name        = "tf-state-management"
  description = "Terraform Remote State Management"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowEC2",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "role_policy" {
  role = aws_iam_role.role.id

  name = "tf-state-management-policy"

  policy = local.iam_policy
}
