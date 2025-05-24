################## VPC ##################

resource "aws_vpc" "benevolate_vpc" { 
  cidr_block = var.vpc_cidr_block
  enable_dns_support = var.vpc_enable_dns_support 
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  tags = {
    Name = var.vpc_tags 
  }
}


################## Subnet ##################

                ## Public ##

resource "aws_subnet" "benevolate_public_subnet" {
  for_each = var.subnets

  vpc_id     = aws_vpc.benevolate_vpc.id
  cidr_block = each.value.subnet_cidr
  availability_zone = each.value.subnet_availability_zone
  map_public_ip_on_launch = each.value.subnet_public
  tags = {
    Name = each.key
    Type = each.value.subnet_public ? "public" : "private"
  }
  depends_on = [  aws_vpc.benevolate_vpc ]
}



# ##############

# resource "aws_internet_gateway" "my_gateway" {
#   vpc_id = aws_vpc.my_vpc.id
#   depends_on = [  aws_vpc.my_vpc ]
# }


# resource "aws_route_table" "my_route_table" {
#   vpc_id = aws_vpc.my_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.my_gateway.id
#   }
#   depends_on = [  aws_vpc.my_vpc, aws_internet_gateway.my_gateway ]
# }

# resource "aws_route_table_association" "public_association" {
#   subnet_id      = aws_subnet.my_subnet.id
#   route_table_id = aws_route_table.my_route_table.id
# }


# resource "aws_security_group" "ecs_security_group" {
#   name        = var.sg_name
#   description = "Allow inbound traffic to ECS tasks"
#   vpc_id      = aws_vpc.my_vpc.id  


#   egress {
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1" 
#   }

#   ingress {
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }


#   ### For EFS #####
#   ingress {
#     from_port   = 2049
#     to_port     = 2049
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"]  # or your VPC CIDR
#   }

#   depends_on = [ aws_vpc.my_vpc ]
# }
