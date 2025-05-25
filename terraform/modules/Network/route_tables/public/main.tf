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

data "terraform_remote_state" "gateway" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/gateway/terraform.tfstate"
    region = "us-east-2"
  }
}


##### SUBNET #####

module "benevolate_private_route_table" {
  source                    = "../../../../resources/Network/benevolate_application/route_tables/public"
  
  ### Private Route Table ####
  vpc_id = data.terraform_remote_state.vpc.outputs.module_vpc_id
  internet_gateway_id = data.terraform_remote_state.gateway.outputs.module_benevolate_internet_gateway_id
  public_subnet_id = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-load-balancer-1"]


  # sg_name = local.sg_name
  
}