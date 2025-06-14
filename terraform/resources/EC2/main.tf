data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
}

resource "aws_instance" "benevolate_ec2_instance" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name
  user_data = templatefile("${path.module}/user-data.sh", {
    efs1_dns_name = var.efs1_dns_name
    efs2_dns_name = var.efs2_dns_name
    efs3_dns_name = var.efs3_dns_name
    hostname      = var.host_name
    AZ            = "dummy"
    AWS_REGION    = "dummy"
  })

  tags = {
    Name = var.ec2_tag_name
  }
} 