terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}


locals {
  tag_name       = "Benevolate"
  vpc_cidr_block = "10.0.0.0/16"

}



##### VPC #####

module "benevolate_vpc" {

  source                   = "../../../resources/Network/benevolate_application/vpc"
  vpc_tags                 = local.tag_name
  vpc_cidr_block           = local.vpc_cidr_block
  vpc_enable_dns_support   = true
  vpc_enable_dns_hostnames = true

}
