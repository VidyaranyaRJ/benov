output "certificate_arn" {
  value = aws_acm_certificate.benevolate_https_certification.arn
}

output "certificate_validation_arn" {
  value = aws_acm_certificate_validation.benevolate_acm_certificate_validation.id
}




