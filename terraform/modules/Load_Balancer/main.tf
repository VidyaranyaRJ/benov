terraform {
  backend "s3" {
    bucket  = "vj-test-benvolate"
    key     = "terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

###################### Data ###############################

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

data "terraform_remote_state" "security_group" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "Network/security_group/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "EC2/terraform.tfstate"
    region = "us-east-2"
  }
}


###################### Locals ###############################

locals {
  load_balancer_name = "Application-load-balancer"
  target_group_name  = "ALB-TG"
  port               = 80
  protocol           = "HTTP"
}


###################### Module ###############################

module "load_balancer_1" {
  source             = "../../resources/Load Balancer"
  load_balancer_name = local.load_balancer_name
  vpc_id             = data.terraform_remote_state.vpc.outputs.module_vpc_id
  security_group_id  = data.terraform_remote_state.security_group.outputs.module_benevolate_security_group_id
  ec2_instance_ids = [
    data.terraform_remote_state.ec2.outputs.module_instance_1_id,
    data.terraform_remote_state.ec2.outputs.module_instance_2_id
    # data.terraform_remote_state.ec2.outputs.module_instance_3_id,
    # data.terraform_remote_state.ec2.outputs.module_instance_4_id,
    # data.terraform_remote_state.ec2.outputs.module_instance_5_id
  ]
  target_group_name = local.target_group_name
  subnet_ids = [
    data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-load-balancer-1"],
    data.terraform_remote_state.subnet.outputs.module_subnet_id["Benevolate-subnet-load-balancer-2"]
  ]

  internal                            = false
  load_balancer_type                  = "application"
  aws_lb_target_group_port            = 3000
  aws_lb_target_group_protocol        = local.protocol
  aws_lb_target_group_attachment_port = 3000
  aws_lb_listener_port                = local.port
  aws_lb_listener_protocol            = local.protocol
  stickiness_enabled                  = true
  stickiness_cookie_duration          = 5
  type                                = "load_balancer_cookie"
  aws_lb_target_group_health_check_config = {
    path                = "/health"
    protocol            = local.protocol
    interval            = 20
    timeout             = 4
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}






