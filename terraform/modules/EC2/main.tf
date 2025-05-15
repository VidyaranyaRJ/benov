data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
}

resource "aws_instance" "ecs_instance" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = true
  key_name                    = "vj-test"
  user_data = templatefile("user-data.sh", {
      efs1_dns_name  = var.efs1_dns_name
      efs2_dns_name  = var.efs2_dns_name
      efs3_dns_name  = var.efs3_dns_name
      git_repo_url   = var.git_repo_url
    })

  tags = {
    Name = var.ec2_tag_name
  }
} 