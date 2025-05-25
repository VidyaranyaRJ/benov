################## Internet Gateway ##################

resource "aws_internet_gateway" "benevolate_internet_gateway" {
  vpc_id = var.vpc_id
  tags = {
    Name = var.tag_name_internet_gateway
  }
}

################## NAT Gateway ##################

## Elastic IP for NAT Gateway ##

resource "aws_eip" "benevolate_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.benevolate_internet_gateway]
}

## NAT Gateway ##

resource "aws_nat_gateway" "benevolate_nat_gateway" {
  allocation_id = aws_eip.benevolate_eip.id
  subnet_id     = var.public_subnet_id_nat_gateway

  tags = {
    Name = var.tag_name_nat_gateway
  }
  depends_on = [aws_eip.benevolate_eip]

}
