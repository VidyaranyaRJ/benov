##### VPC #####
output "module_vpc_id" {
  value = module.benevolate_vpc.vpc_id
}


##### SUBNET #####
# output "module_subnet_id" {
#   value = module.network.subnet_ids
# }

# output "first_subnet_id" {
#   value = values(module.network.subnet_ids)[0]
# }

# output "module_security_group_id" {
#   value = module.network.security_group_id
# }




