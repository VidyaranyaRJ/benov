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


variable "efs1_dns_name" {
  type = string
  description = "EFS DNS name"
}

variable "efs2_dns_name" {
  type = string
  description = "EFS DNS name"
}

variable "efs3_dns_name" {
  type = string
  description = "EFS DNS name"
}


variable "ami" {
  type = string
}


variable "git_repo_url" {
  type = string
}
