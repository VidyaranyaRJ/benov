variable "region" {
  type        = string
}

variable "ami" {
  type        = string
}

variable "instance_type" {
  type        = string
}

# variable "AWS_ACCESS_KEY_ID" {
#   type        = string
# }

# variable "AWS_SECRET_ACCESS_KEY" {
#   type        = string
# }



# variable "sg_name" {
#   type        = string
# }

variable "environment" {
  description = "Environment to deploy to (qa or prod)"
  type        = string
}
# variable "ec2_name" {
#   type        = string
#   description = "Name tag for the EC2 instance"
# }


variable "alb_name" {
  type = string
}



