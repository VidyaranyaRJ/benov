terraform {
  backend "s3" {
    bucket         = "vj-test-ecr-79"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}

locals {
  creation_token_efs1 = "App Data"
  tag_name_efs1 = "GitHub - code"

  creation_token_efs2 = "ORG Data"
  tag_name_efs2 = "GitHub - code"

  creation_token_efs3 = "User Data"
  tag_name_efs3 = "GitHub - code"
}


################################# EFS #################################

module "efs" {
  source                                 = "../../modules/EFS"
  creation_token = local.creation_token_efs1
  tag_name = local.tag_name_efs1
}

module "efs" {
  source                                 = "../../modules/EFS"
  creation_token = local.creation_token_efs2
  tag_name = local.tag_name_efs2
}

module "efs" {
  source                                 = "../../modules/EFS"
  creation_token = local.creation_token_efs3
  tag_name = local.tag_name_efs3
}