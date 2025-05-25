################## Private Route Table  ##################

# Private Route Table (uses NAT Gateway)
resource "aws_route_table" "benevolate_private_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }
}

# Route Table Association: Private Subnet
resource "aws_route_table_association" "benevolate_private_route_table_association" {
  subnet_id      = var.private_subnet_id
  route_table_id = aws_route_table.benevolate_private_route_table.id
}








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
