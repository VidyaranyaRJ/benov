resource "aws_efs_file_system" "benevolate_efs" {
  creation_token = var.creation_token

  tags = {
    Name = var.tag_name
  }

}


resource "aws_efs_mount_target" "benevolate_efs_mount" {
  file_system_id  = aws_efs_file_system.benevolate_efs.id
  subnet_id       = var.subnet_id_for_efs_mount_target
  security_groups = [var.security_group_id_for_efs]
}