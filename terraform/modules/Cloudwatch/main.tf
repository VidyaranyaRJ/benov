terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}


data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "EC2/terraform.tfstate"
    region = "us-east-2"
  }
}



################################# EFS #################################

module "cloudwatch" {
  source                         = "../../resources/Cloudwatch"
    ec2_instance_ids = [
    data.terraform_remote_state.ec2.outputs.module_instance_1_id,
    # data.terraform_remote_state.ec2.outputs.module_instance_2_id,
    # data.terraform_remote_state.ec2.outputs.module_instance_3,
    # data.terraform_remote_state.ec2.outputs.module_instance_4,
    # data.terraform_remote_state.ec2.outputs.module_instance_5
  ]
  cloudwatch_s3_path = "Cloudwatch/cloudwatch-agent-config.json"
  cloudwatch_s3_bucket = "vj-test-benvolate"
  region = "us-east-2"
}

