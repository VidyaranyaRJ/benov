###################################### VPC ######################################

variable "vpc_cidr_block" {
  type        = string
}

variable "vpc_enable_dns_support" {
  type        = bool
  default = true
}

variable "vpc_enable_dns_hostnames" {
  type        = bool
  default = true
}

variable "vpc_tags" {
  type        = string
}



# ###################################### Subnets ######################################

# variable "subnets" {
#   type = map(object({
#     subnet_cidr   = string
#     subnet_availability_zone     = string
#     subnet_public = bool
#   }))
# }

###################################### NAT Gateway ######################################
# variable "public_subnet_id_nat_gateway" {
#   type        = string
# }

# variable "tag_name_nat_gateway" {
#   type        = string
# }


















# variable "sg_name" {
#   type        = string
# }

