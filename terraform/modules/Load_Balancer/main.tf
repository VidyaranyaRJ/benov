terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

###################### Data ###############################

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/terraform.tfstate"
    region = "us-east-2"
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


###################### Locals ###############################

locals {
  load_balancer_name = "Application-load-balancer"
  target_group_name  = "ALB-TG"
}


###################### Module ###############################

module "load_balancer_1" {
  source             = "../../modules/Load Balancer"
  load_balancer_name = local.load_balancer_name
  vpc_id             = data.terraform_remote_state.network.outputs.module_vpc_id
  security_group_id  = data.terraform_remote_state.network.outputs.module_security_group_id
  ec2_instance_ids = [
    data.terraform_remote_state.ec2.outputs.module_instance_1_id_for_ssm
    # data.terraform_remote_state.ec2.outputs.module_instance_2_id_for_ssm,
    # data.terraform_remote_state.ec2.outputs.module_instance_3_id_for_ssm,
    # data.terraform_remote_state.ec2.outputs.module_instance_4_id_for_ssm,
    # data.terraform_remote_state.ec2.outputs.module_instance_5_id_for_ssm
  ]
  target_group_name = local.target_group_name
  subnet_ids = [
    data.terraform_remote_state.network.outputs.module_subnet_id,
    data.terraform_remote_state.network.outputs.module_subnet_id_2
  ]
}






