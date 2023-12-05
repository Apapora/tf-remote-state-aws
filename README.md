# tf-remote-state-aws

These are Terraform files for setting up hosted remote state files on S3 and DynamoDB.

Once these have been Terraform applied, you'll need to use the following configuration in future Terraform projects:

```
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "${aws_s3_bucket.my_bucket.id}"
    dynamodb_table = "${aws_dynamodb_table.my_dynamodb_table.id}"
    role_arn       = "${aws_iam_role.role.arn}"
    key            = "{some-project-name}" // must be unique across projects
  }
}
```
