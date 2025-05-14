variable "region" {
  type        = string
}

variable "ami" {
  type        = string
}

variable "instance_type" {
  type        = string
}

variable "sg_name" {
  type        = string
}



variable "ec2_tag_name" {
  type = string
  description = "EC2 tag name"
}
