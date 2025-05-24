output "vpc_id" {
  value = aws_vpc.benevolate_vpc.id
}


output "subnet_id" {
  value = aws_subnet.benevolate_public_subnet.id
}


# output "security_group_id" {
#   value = aws_security_group.ecs_security_group.id
# }

