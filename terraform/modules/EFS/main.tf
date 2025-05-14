resource "aws_efs_file_system" "efs_github" {
  creation_token = var.creation_token

  tags = {
    Name = var.tag_name
  }
}



resource "aws_efs_mount_target" "code_efs" {
  file_system_id  = aws_efs_file_system.code_efs.id
  subnet_id       = var.subnet
  security_groups = [var.sg_id]
}