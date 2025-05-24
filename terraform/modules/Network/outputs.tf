
output "module_vpc_id" {
  value = module.network.vpc_id
}



output "module_subnet_id" {
  value = module.network.subnet_ids
}

output "module_subnet_id_1" {
  value = module.network.subnet_ids[0]
}



# output "module_security_group_id" {
#   value = module.network.security_group_id
# }




