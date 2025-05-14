resource "aws_efs_file_system" "efs_github" {
  creation_token = var.creation_token

  tags = {
    Name = var.tag_name
  }
}



