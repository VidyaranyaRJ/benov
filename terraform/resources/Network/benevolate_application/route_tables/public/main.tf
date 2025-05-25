################## Public Route Table ##################

# Public Route Table
resource "aws_route_table" "benevolate_public_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }
  tags = {
    Name = var.public_route_table_tag_name
  }
}

# Route Table Association: Public Subnet
resource "aws_route_table_association" "benevolate_public_route_table_association" {
  subnet_id      = var.public_subnet_id
  route_table_id = aws_route_table.benevolate_public_route_table.id
}
