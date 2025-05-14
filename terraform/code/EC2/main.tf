terraform {
  backend "s3" {
    bucket         = "vj-test-benv"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}


data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "vj-test-benv"
    key    = "network/terraform.tfstate"
    region = "us-east-2"
  }
}


locals {
  ec2_tag_name_tag1 = "Instance_1"
  ec2_tag_name_tag2 = "Instance_2"
  ec2_tag_name_tag3 = "Instance_3"
  ec2_tag_name_tag4 = "Instance_4"
  ec2_tag_name_tag5 = "Instance_5"

}



module "Instance_1" {
  source                                 = "../../modules/EC2"
  subnet       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id        = data.terraform_remote_state.network.outputs.module_security_group_id
  ec2_tag_name = local.ec2_tag_name_tag1

}


module "Instance_2" {
  source                                 = "../../modules/EC2"
  subnet       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id        = data.terraform_remote_state.network.outputs.module_security_group_id
  ec2_tag_name                           = local.ec2_tag_name_tag2
}


module "Instance_3" {
  source                                 = "../../modules/EC2"
  subnet       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id        = data.terraform_remote_state.network.outputs.module_security_group_id
  ec2_tag_name = local.ec2_tag_name_tag3

}


module "Instance_4" {
  source                                 = "../../modules/EC2"
  subnet       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id        = data.terraform_remote_state.network.outputs.module_security_group_id
  ec2_tag_name = local.ec2_tag_name_tag4
}


module "Instance_5" {
  source                                 = "../../modules/EC2"
  subnet       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id        = data.terraform_remote_state.network.outputs.module_security_group_id
  ec2_tag_name = local.ec2_tag_name_tag5
}
