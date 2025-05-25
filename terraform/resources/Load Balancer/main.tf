locals {
  default_health_check = {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "benevolate_application_load_balancer" {
  name               = var.load_balancer_name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]
}


resource "aws_lb_target_group" "benevolate_application_target_group" {
  name     = var.target_group_name
  port     = var.aws_lb_target_group_port
  protocol = var.aws_lb_target_group_protocol
  vpc_id   = var.vpc_id

  dynamic "health_check" {
    for_each = var.aws_lb_target_group_health_check_config != null ? [var.aws_lb_target_group_health_check_config] : [local.default_health_check]

    content {
      path                = health_check.value.path
      protocol            = health_check.value.protocol
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
}


resource "aws_lb_target_group_attachment" "tg_attachments" {
  count            = length(var.ec2_instance_ids)
  target_group_arn = aws_lb_target_group.benevolate_application_target_group.arn
  target_id        = var.ec2_instance_ids[count.index]
  port             = var.aws_lb_target_group_attachment_port
}



resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.benevolate_application_load_balancer.arn
  port              = var.aws_lb_listener_port
  protocol          = var.aws_lb_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.benevolate_application_target_group.arn
  }
  depends_on = [
    aws_lb_target_group_attachment.tg_attachments
  ]
}