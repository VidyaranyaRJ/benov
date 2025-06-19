data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
}

  
  
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  # vars = {
  #   hostname       = var.hostname
  #   AZ             = var.az
  #   AWS_REGION     = var.region
  #   efs1_dns_name  = "${var.efs_code_id}.efs.${var.region}.amazonaws.com"
  #   efs2_dns_name  = "${var.efs_data_id}.efs.${var.region}.amazonaws.com"
  #   efs3_dns_name  = "${var.efs_logs_id}.efs.${var.region}.amazonaws.com"
  # }
}


resource "aws_instance" "benevolate_ec2_instance" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name
  user_data     = data.template_file.user_data.rendered


  tags = {
    Name = var.ec2_tag_name
  }

  lifecycle {
    ignore_changes = [user_data] 
  }
} 