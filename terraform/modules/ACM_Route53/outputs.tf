output "module_certificate_arn" {
  value = module.acm_route53.certificate_arn
}

output "module_certificate_validation_arn" {
  value = module.acm_route53.certificate_validation_arn
}


