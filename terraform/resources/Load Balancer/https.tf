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
    aws_lb.benevolate_application_load_balancer
  ]
}
