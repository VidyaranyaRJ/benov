terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}


locals {
  tag_name = "Benevolate"
  vpc_cidr_block = "10.0.0.0/16"

  sg_name ="security-group"

}

module "benevolate_vpc" {
  source                    = "../../resources/Network/benevolate_application/vpc"

  #### VPC ####
  vpc_tags                  = local.tag_name
  vpc_cidr_block            = local.vpc_cidr_block
  vpc_enable_dns_support    = true
  vpc_enable_dns_hostnames  = true

  # #### Subnets ####
  # subnets = {
  #   Benevolate-subnet-load-balancer-1  = { subnet_cidr = "10.0.1.0/24", subnet_availability_zone = "us-east-2a", subnet_public = true }
  #   Benevolate-subnet-load-balancer-2  = { subnet_cidr = "10.0.2.0/24", subnet_availability_zone = "us-east-2b", subnet_public = true }
  #   Benevolate-subnet-application-1    = { subnet_cidr = "10.0.3.0/24", subnet_availability_zone = "us-east-2a", subnet_public = false }
  # }
  
  #### NAT Gateway ####
  # public_subnet_id_nat_gateway = module.network.subnet_ids["Benevolate-subnet-load-balancer-1"]
  # tag_name_nat_gateway = local.tag_name

  # sg_name = local.sg_name
  
}