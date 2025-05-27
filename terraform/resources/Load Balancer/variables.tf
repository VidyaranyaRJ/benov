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


variable "stickiness_enabled" {
  type = bool
}

variable "stickiness_cookie_duration" {
  type = number
}

variable "type" {
  type = string
}


variable "lb_listener_ssl_policy" {
  type = string
}


variable "aws_lb_listener_https_port" {
  type = string
}



variable "aws_lb_listener_https_protocol" {
  type = string
}


variable "aws_lb_listener_https_status_code" {
  type = string
}


variable "acm_certificate_arn" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}





