output "alb_dns_name" {
  value = aws_lb.benevolate_application_load_balancer.dns_name
}