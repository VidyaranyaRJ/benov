################## Subnet ##################

resource "aws_subnet" "benevolate_subnet" {
  for_each = var.subnets

  vpc_id     = var.vpc_id
  cidr_block = each.value.subnet_cidr
  availability_zone = each.value.subnet_availability_zone
  map_public_ip_on_launch = each.value.subnet_public
  tags = {
    Name = each.key
    Type = each.value.subnet_public ? "public" : "private"
  }
}
