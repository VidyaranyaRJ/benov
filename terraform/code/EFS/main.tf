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
    key    = "Network/terraform.tfstate"
    region = "us-east-2"
  }
}


locals {
  creation_token_efs1 = "App -GitHub - code"
  tag_name_efs1 = "App Data"

  creation_token_efs2 = "ORG GitHub - code"
  tag_name_efs2 = "ORG Data"

  creation_token_efs3 = "User GitHub - code"
  tag_name_efs3 = "User Data"
  
}


################################# EFS #################################

module "efs1" {
  source                                 = "../../modules/EFS"
  creation_token = local.creation_token_efs1
  tag_name = local.tag_name_efs1
  subnet_id_for_efs       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id_id_for_efs = data.terraform_remote_state.network.outputs.module_security_group_id
}

module "efs2" {
  source                                 = "../../modules/EFS"
  creation_token = local.creation_token_efs2
  tag_name = local.tag_name_efs2
  subnet_id_for_efs       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id_id_for_efs = data.terraform_remote_state.network.outputs.module_security_group_id
}

module "efs3" {
  source                                 = "../../modules/EFS"
  creation_token = local.creation_token_efs3
  tag_name = local.tag_name_efs3
  subnet_id_for_efs       = data.terraform_remote_state.network.outputs.module_subnet_id
  sg_id_id_for_efs = data.terraform_remote_state.network.outputs.module_security_group_id
}