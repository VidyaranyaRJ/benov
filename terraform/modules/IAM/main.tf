terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}


module "benevolate_ec2_iam" {
  source = "../../resources/IAM"

  iam_role_name = "benevolate-ssm-role"

  assume_role_policy_json = {
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["ec2.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  }

  iam_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}
