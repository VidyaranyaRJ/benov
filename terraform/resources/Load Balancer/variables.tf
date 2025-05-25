variable "subnet_ids" {
  type = list(string)
}

variable "ec2_instance_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "target_group_name" {
  type = string
}

variable "load_balancer_name" {
  type = string
}

variable "security_group_id" {
  type = string
}