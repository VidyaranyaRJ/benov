###################################### NAT Gateway ######################################
variable "vpc_id" {
  type = string
}

variable "internet_gateway_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "public_route_table_tag_name" {
  type = string
}