terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}



######################### DATA #########################

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/vpc/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "subnet" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/subnet/terraform.tfstate"
    region = "us-east-2"
  }
}




locals {
  tag_name_nat_gateway = "Benevolate_nat_gateway"
  tag_name_internet_gateway = "Benevolate_internet_gateway"
}

##### SUBNET #####

module "benevolate_gateway" {
  source                    = "../../../resources/Network/benevolate_application/internet_and_nat_gateway"

  ### NAT Gateway ####
  public_subnet_id_nat_gateway = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-load-balancer-1"]
  tag_name_nat_gateway = local.tag_name_nat_gateway
  vpc_id = data.terraform_remote_state.vpc.outputs.module_vpc_id
  tag_name_internet_gateway = local.tag_name_internet_gateway
  # sg_name = local.sg_name
  
}