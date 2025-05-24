terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}


locals {
  vpc_tags = "Benevolate-vpc"
  vpc_cidr_block = "10.0.0.0/16"
  sg_name ="security-group"

}

module "network" {
  source                    = "../../resources/Network/benevolate_application_vpc"
  vpc_tags                  = local.vpc_tags
  vpc_cidr_block            = local.vpc_cidr_block
  vpc_enable_dns_support    = true
  vpc_enable_dns_hostnames  = true
  subnets = {
    Benevolate-subnet-load-balancer-1  = { subnet_cidr = "10.0.1.0/24", subnet_availability_zone = "us-east-2a", subnet_public = true }
    Benevolate-subnet-load-balancer-2  = { subnet_cidr = "10.0.2.0/24", subnet_availability_zone = "us-east-2b", subnet_public = true }
    Benevolate-subnet-application-1 = { subnet_cidr = "10.0.3.0/24", subnet_availability_zone = "us-east-2a", subnet_public = false }
  }
  


  # sg_name = local.sg_name
}