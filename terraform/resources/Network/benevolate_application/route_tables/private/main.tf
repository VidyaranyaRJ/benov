################## Private Route Table  ##################

# Private Route Table (uses NAT Gateway)
resource "aws_route_table" "benevolate_private_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }

  tags = {
    Name = var.private_route_table_tag_name
  }
}

# Route Table Association: Private Subnet
resource "aws_route_table_association" "benevolate_private_route_table_association" {
  subnet_id      = var.private_subnet_id
  route_table_id = aws_route_table.benevolate_private_route_table.id
}

