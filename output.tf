output "bucket" {
  description = "The name of the S3 Bucket used for Terraform Remote State."
  value       = aws_s3_bucket.my_bucket.bucket
}

output "dynamodb" {
  description = "The DynamoDB Table used for locking the Remote State."
  value       = aws_dynamodb_table.my_dynamodb_table.name
}

output "role" {
  description = "The ARN of the IAM Role that is used to access the Remote State"
  value       = aws_iam_role.role.arn
}

output "example_backend_configuration" {
  description = "Provides an example of what the `backend` configuration would look like in order to use the provisioned Remote State"
  value       = <<BACKEND

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "${aws_s3_bucket.my_bucket.id}"
    dynamodb_table = "${aws_dynamodb_table.my_dynamodb_table.id}"
    role_arn       = "${aws_iam_role.role.arn}"
    key            = "{some-project-name}" // must be unique across projects
  }
}
BACKEND
}
