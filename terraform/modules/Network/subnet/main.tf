terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/terraform.tfstate"
    region = "us-east-2"
  }
}


##### SUBNET #####

module "benevolate_subnet" {
  source                    = "../../../resources/Network/benevolate_application/subnet"

  #### Subnets ####
  vpc_id = data.terraform_remote_state.network.outputs.module_vpc_id
  subnets = {
    Benevolate-subnet-load-balancer-1  = { subnet_cidr = "10.0.1.0/24", subnet_availability_zone = "us-east-2a", subnet_public = true }
    Benevolate-subnet-load-balancer-2  = { subnet_cidr = "10.0.2.0/24", subnet_availability_zone = "us-east-2b", subnet_public = true }
    Benevolate-subnet-application-1    = { subnet_cidr = "10.0.3.0/24", subnet_availability_zone = "us-east-2a", subnet_public = false }
  }
  
  #### NAT Gateway ####
  # public_subnet_id_nat_gateway = module.network.subnet_ids["Benevolate-subnet-load-balancer-1"]
  # tag_name_nat_gateway = local.tag_name

  # sg_name = local.sg_name
  
}