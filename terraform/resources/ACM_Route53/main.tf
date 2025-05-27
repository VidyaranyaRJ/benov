resource "aws_acm_certificate" "benevolate_https_certification" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags = {
    Name = var.acm_certificate_tag_name
  }
}



##creates DNS validation records for ACM certificate validation
resource "aws_route53_record" "benevolate_route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.benevolate_https_certification.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = var.route53_record_ttl
  records = [each.value.value]
}



resource "aws_acm_certificate_validation" "benevolate_acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.benevolate_https_certification.arn
  validation_record_fqdns = [for r in aws_route53_record.benevolate_route53_record : r.fqdn]
}



