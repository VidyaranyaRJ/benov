output "subnet_ids" {
  value = {
    for name, subnet in aws_subnet.benevolate_subnet :
    name => subnet.id
  }
}




