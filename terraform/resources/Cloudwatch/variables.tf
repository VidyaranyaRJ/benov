variable "ec2_instance_ids" {
  description = "A list of EC2 instance IDs to configure the CloudWatch Agent."
  type        = list(string)
}

variable "cloudwatch_s3_bucket" {
  description = "The name of the S3 bucket where the CloudWatch Agent configuration file is stored."
  type        = string
}

variable "cloudwatch_s3_path" {
  description = "The path to the CloudWatch Agent configuration file in the S3 bucket."
  type        = string
}

variable "region" {
  description = "The AWS region where the CloudWatch Agent will be running."
  type        = string
  default     = "us-east-1"  # Default region
}
