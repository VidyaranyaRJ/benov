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

