###################################### Subnets ######################################

variable "subnets" {
  type = map(object({
    subnet_cidr              = string
    subnet_availability_zone = string
    subnet_public            = bool
  }))
}


variable "vpc_id" {
  type = string
}

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

