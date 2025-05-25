terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/vpc/terraform.tfstate"
    region = "us-east-2"
  }
}


##### Security Group #####

module "benevolate_subnet" {
  source                    = "../../../resources/Network/benevolate_application/security_group"

  security_group_name = "Benevolate-security-group"
  vpc_id              = data.terraform_remote_state.vpc.outputs.module_vpc_id




  security_group_ingress_rules = [
    { description = "Allow SSH", from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "Allow HTTP", from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "Allow HTTPS", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "Node.js", from_port = 3000, to_port = 3000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "EFS", from_port = 2049, to_port = 2049, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"] }
  ]

  security_group_egress_rules = [
    { description = "Allow External", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]

}

