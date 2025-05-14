terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"  
    key            = "terraform.tfstate"  
    region         = "us-east-2" 
    encrypt        = true
  }
}


locals {
  sg_name ="security-group"
}

module "network" {
  source                                 = "../../modules/Network"
  sg_name = local.sg_name
}
