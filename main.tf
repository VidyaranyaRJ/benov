# Terraform to dynamically fetch EFS ID and EC2 IDs,
# generate buildspec.yml, and configure CodeBuild

# --- Remote State for EC2 ---
data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "EC2/terraform.tfstate"
    region = "us-east-2"
  }
}

# --- Remote State for EFS ---
data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "EFS/terraform.tfstate"
    region = "us-east-2"
  }
}

# --- Locals ---
locals {
  ec2_instance_ids = join(" ", [
    data.terraform_remote_state.ec2.outputs.module_instance_1_id,
    data.terraform_remote_state.ec2.outputs.module_instance_2_id
  ])

  efs_id = data.terraform_remote_state.efs.outputs.module_efs1_id
}

# --- Generate Buildspec Dynamically ---
resource "local_file" "buildspec" {
  filename = "${path.module}/Nodejs/buildspec.yml"
  content  = templatefile("${path.module}/Nodejs/buildspec-template.yml", {
    efs_id       = local.efs_id,
    instance_ids = local.ec2_instance_ids
  })
}


# --- CodeBuild IAM Role ---
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-nodejs-to-efs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- CodeBuild Project ---
resource "aws_codebuild_project" "nodejs_to_efs" {
  name          = "NodejsToEfs"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type     = "GITHUB"
    location = "https://github.com/VidyaranyaRJ/benov.git"
    buildspec = "Nodejs/buildspec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
  }
}
