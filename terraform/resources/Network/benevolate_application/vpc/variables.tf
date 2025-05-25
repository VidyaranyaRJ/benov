###################################### VPC ######################################

variable "vpc_cidr_block" {
  type = string
}

variable "vpc_enable_dns_support" {
  type    = bool
  default = true
}

variable "vpc_enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "vpc_tags" {
  type = string
}

