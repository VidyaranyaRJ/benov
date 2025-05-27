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




## Maps our domain to the load balancer
resource "aws_route53_record" "benevolate_maps_domain_to_load_balancer" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.benevolate_application_load_balancer.dns_name
    zone_id                = aws_lb.benevolate_application_load_balancer.zone_id
    evaluate_target_health = true
  }

  depends_on = [
    aws_acm_certificate_validation.benevolate_acm_certificate_validation
  ]
}