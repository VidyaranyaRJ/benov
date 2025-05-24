resource "aws_efs_file_system" "efs" {
  creation_token = var.creation_token

  tags = {
    Name = var.tag_name
  }
}



resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id_for_efs
  security_groups = [var.sg_id_id_for_efs]
}