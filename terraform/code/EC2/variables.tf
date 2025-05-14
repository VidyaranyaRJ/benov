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

variable "AWS_ACCESS_KEY_ID" {
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type        = string
}


variable "ec2_tag_name" {
  type = string
  description = "EC2 tag name"
}
