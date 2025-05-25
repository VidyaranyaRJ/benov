resource "aws_lb_target_group" "app_tg" {
  name     = var.target_group_name #######
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id ########

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}



resource "aws_lb" "app_alb" {
  name               = var.load_balancer_name
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id] ####
}



resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}



resource "aws_lb_target_group_attachment" "tg_attachments" {
  count            = length(var.ec2_instance_ids) ############
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = var.ec2_instance_ids[count.index]
  port             = 80
}
