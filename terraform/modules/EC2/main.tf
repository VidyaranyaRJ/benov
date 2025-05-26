terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

###################### Data ###############################

data "terraform_remote_state" "subnet" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/subnet/terraform.tfstate"
    region = "us-east-2"
  }
}


data "terraform_remote_state" "security_group" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/security_group/terraform.tfstate"
    region = "us-east-2"
  }
}


data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "EFS/terraform.tfstate"
    region = "us-east-2"
  }
}



###################### Locals ###############################

locals {
  ec2_tag_name_tag1 = "Instance_1"
  ec2_tag_name_tag2 = "Instance_2"
  ec2_tag_name_tag3 = "Instance_3"
  ec2_tag_name_tag4 = "Instance_4"
  ec2_tag_name_tag5 = "Instance_5"

  hostname_instance_1 = "Sun"
  hostname_instance_2 = "Mercury"
  hostname_instance_3 = "Venus"
  hostname_instance_4 = "Earth"
  hostname_instance_5 = "Mars"

  ami = "ami-0d0f28110d16ee7d6"

}

###################### Module ###############################

module "instance_1" {
  source                      = "../../resources/EC2"
  ami                         = local.ami
  subnet                      = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-application-1"]
  sg_id                       = data.terraform_remote_state.security_group.outputs.module_benevolate_security_group_id
  ec2_tag_name                = local.ec2_tag_name_tag1
  efs1_dns_name               = data.terraform_remote_state.efs.outputs.module_efs1_dns_name
  efs2_dns_name               = data.terraform_remote_state.efs.outputs.module_efs2_dns_name
  efs3_dns_name               = data.terraform_remote_state.efs.outputs.module_efs3_dns_name
  host_name                   = local.hostname_instance_1
  associate_public_ip_address = false
}


# module "instance_2" {
#   source                      = "../../resources/EC2"
#   ami                         = local.ami
#   subnet                      = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-application-1"]
#   sg_id                       = data.terraform_remote_state.security_group.outputs.module_benevolate_security_group_id
#   ec2_tag_name                = local.ec2_tag_name_tag2
#   efs1_dns_name               = data.terraform_remote_state.efs.outputs.module_efs1_dns_name
#   efs2_dns_name               = data.terraform_remote_state.efs.outputs.module_efs2_dns_name
#   efs3_dns_name               = data.terraform_remote_state.efs.outputs.module_efs3_dns_name
#   host_name                   = local.hostname_instance_2
#   associate_public_ip_address = false
# }


# module "instance_3" {
#   source                                 = "../../resources/EC2"
#   ami = local.ami
#   subnet        = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-application-1"]
#   sg_id         = data.terraform_remote_state.security_group.outputs.module_benevolate_security_group_id
#   ec2_tag_name = local.ec2_tag_name_tag3
#   efs1_dns_name = data.terraform_remote_state.efs.outputs.module_efs1_dns_name
#   efs2_dns_name = data.terraform_remote_state.efs.outputs.module_efs2_dns_name
#   efs3_dns_name = data.terraform_remote_state.efs.outputs.module_efs3_dns_name
#   host_name = local.hostname_instance_3
#   associate_public_ip_address = false
# }


# module "instance_4" {
#   source                                 = "../../resources/EC2"
#   ami = local.ami
#   subnet        = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-application-1"]
#   sg_id         = data.terraform_remote_state.security_group.outputs.module_benevolate_security_group_id
#   ec2_tag_name = local.ec2_tag_name_tag4
#   efs1_dns_name = data.terraform_remote_state.efs.outputs.module_efs1_dns_name
#   efs2_dns_name = data.terraform_remote_state.efs.outputs.module_efs2_dns_name
#   efs3_dns_name = data.terraform_remote_state.efs.outputs.module_efs3_dns_name
#   host_name = local.hostname_instance_4
#   associate_public_ip_address = false
# }


# module "instance_5" {
#   source                                 = "../../resources/EC2"
#   ami = local.ami
#   subnet        = data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-application-1"]
#   sg_id         = data.terraform_remote_state.security_group.outputs.module_benevolate_security_group_id
#   ec2_tag_name = local.ec2_tag_name_tag5
#   efs1_dns_name = data.terraform_remote_state.efs.outputs.module_efs1_dns_name
#   efs2_dns_name = data.terraform_remote_state.efs.outputs.module_efs2_dns_name
#   efs3_dns_name = data.terraform_remote_state.efs.outputs.module_efs3_dns_name
#   host_name = local.hostname_instance_5
#   associate_public_ip_address = false
# }
