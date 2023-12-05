# AWS Region
variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

# Tags for resources
variable "tags" {
  description = "A map of tags to apply to AWS resources."
  type        = map(string)
  default = {
    Terraform = "true",
  }
}

# Log Bucket Name
variable "log_bucket_name" {
  description = "The name of the S3 bucket for log storage."
  type        = string
  default     = "apopora-tf-log-bucket"
}

# State Bucket Name
variable "state_bucket_name" {
  description = "The name of the S3 bucket for storing Terraform state files."
  type        = string
  default     = "apopora-tf-state-bucket"
}

# DynamoDB Table Name
variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
  default     = "tf-state-table"
}
