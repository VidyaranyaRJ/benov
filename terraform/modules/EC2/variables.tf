variable "sg_name" {
  type = string
  default = "ecs_sg"
}

variable "subnet" {
  type = string
  description = "Subnet ID to launch instances"
}

variable "sg_id" {
  type = string
  description = "Security group ID"
}


variable "ec2_tag_name" {
  type = string
  description = "EC2 tag name"
}
