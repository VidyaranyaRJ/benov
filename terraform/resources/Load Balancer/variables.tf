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


variable "internal" {
  type = bool
}

variable "load_balancer_type" {
  type = string
}

variable "aws_lb_target_group_port" {
  type = number
}

variable "aws_lb_target_group_protocol" {
  type = string
}

variable "aws_lb_target_group_attachment_port" {
  type = number
}

variable "aws_lb_listener_port" {
  type = number
}

variable "aws_lb_listener_protocol" {
  type = string
}

variable "aws_lb_target_group_health_check_config" {
  type = object({
    path                = string
    protocol            = string
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
  })
  default = null
}

