data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
}

  
  
# data "template_file" "user_data" {
#   template = file("${path.module}/user-data.sh")

#   vars = {
#     hostname       = var.hostname
#     AZ             = var.az
#     AWS_REGION     = var.region
#     efs1_dns_name  = "${var.efs_code_id}.efs.${var.region}.amazonaws.com"
#     efs2_dns_name  = "${var.efs_data_id}.efs.${var.region}.amazonaws.com"
#     efs3_dns_name  = "${var.efs_logs_id}.efs.${var.region}.amazonaws.com"
#   }
# }


# resource "aws_instance" "benevolate_ec2_instance" {
#   ami                         = var.ami
#   instance_type               = "t2.micro"
#   subnet_id                   = var.subnet
#   vpc_security_group_ids      = [var.sg_id]
#   iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
#   associate_public_ip_address = var.associate_public_ip_address
#   key_name                    = var.key_name
#   user_data     = data.template_file.user_data.rendered


#   tags = {
#     Name = var.ec2_tag_name
#   }

#   lifecycle {
#     ignore_changes = [user_data] 
#   }
# } 


# resource "aws_instance" "benevolate_ec2_instance" {
#   ami                         = var.ami
#   instance_type               = "t2.micro"
#   subnet_id                   = var.subnet
#   vpc_security_group_ids      = [var.sg_id]
#   iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
#   associate_public_ip_address = var.associate_public_ip_address
#   key_name                    = var.key_name

#   user_data = <<-EOF
#               #!/bin/bash

#               # Update packages
#               sudo apt-get update -y
#               sudo apt-get install -y nfs-common amazon-efs-utils git binutils python3-pip curl unzip
#               sudo pip3 install botocore

#               # Set alias for python and pip
#               echo "alias python=python3" | sudo tee -a /etc/bash.bashrc
#               echo "alias pip=pip3" | sudo tee -a /etc/bash.bashrc

#               # Create directories for EFS mounts
#               sudo mkdir -p /mnt/efs/code
#               sudo mkdir -p /mnt/efs/data
#               sudo mkdir -p /mnt/efs/logs

#               # Print EFS DNS names
#               echo ">>> EFS DNS names:"
#               echo "Code: ${var.efs_code_id}:/"
#               echo "Data: ${var.efs_data_id}:/"
#               echo "Logs: ${var.efs_logs_id}:/"

#               # Mount the EFS file systems
#               echo ">>> Mounting EFS file systems:"
#               sudo mount -t efs -o tls,iam ${var.efs_code_id}:/ /mnt/efs/code
#               sudo mount -t efs -o tls,iam ${var.efs_data_id}:/ /mnt/efs/data
#               sudo mount -t efs -o tls,iam ${var.efs_logs_id}:/ /mnt/efs/logs

#               # Add EFS to fstab for persistence
#               echo '${var.efs_code_id}:/ /mnt/efs/code efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
#               echo '${var.efs_data_id}:/ /mnt/efs/data efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
#               echo '${var.efs_logs_id}:/ /mnt/efs/logs efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab

#               # Print current mounts
#               echo ">>> Current mounts:"
#               mount | grep /mnt/efs

#               # Install AWS CLI
#               curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#               unzip awscliv2.zip
#               sudo ./aws/install

#               EOF

#   tags = {
#     Name = var.ec2_tag_name
#   }

#   lifecycle {
#     ignore_changes = [user_data]
#   }
# }





resource "aws_instance" "benevolate_ec2_instance" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name

  user_data = <<-EOF
              #!/bin/bash

              # Update packages
              sudo yum update -y
              sudo yum install -y nfs-utils amazon-efs-utils curl unzip python3-pip

              # Set alias for python and pip
              echo "alias python=python3" | sudo tee -a /etc/bashrc
              echo "alias pip=pip3" | sudo tee -a /etc/bashrc

              # Reload bashrc to apply changes
              source /etc/bashrc

              # Install AWS CLI
              echo ">>> Installing AWS CLI..."
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Create directories for EFS mounts
              echo ">>> Creating directories for EFS mounts..."
              sudo mkdir -p /mnt/efs/code
              sudo mkdir -p /mnt/efs/data
              sudo mkdir -p /mnt/efs/logs

              # Define EFS DNS names dynamically using values from terraform_remote_state
              EFS_CODE_DNS="${data.terraform_remote_state.efs.outputs.module_efs1_dns_name}"
              EFS_DATA_DNS="${data.terraform_remote_state.efs.outputs.module_efs2_dns_name}"
              EFS_LOGS_DNS="${data.terraform_remote_state.efs.outputs.module_efs3_dns_name}"

              # Mount the EFS file systems
              echo ">>> Mounting EFS file systems:"
              sudo mount -t efs -o tls,iam $${EFS_CODE_DNS}:/ /mnt/efs/code
              sudo mount -t efs -o tls,iam $${EFS_DATA_DNS}:/ /mnt/efs/data
              sudo mount -t efs -o tls,iam $${EFS_LOGS_DNS}:/ /mnt/efs/logs

              # Add EFS to fstab for persistence
              echo '$${EFS_CODE_DNS}:/ /mnt/efs/code efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
              echo '$${EFS_DATA_DNS}:/ /mnt/efs/data efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
              echo '$${EFS_LOGS_DNS}:/ /mnt/efs/logs efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab

              # Print current mounts
              echo ">>> Current mounts:"
              mount | grep /mnt/efs

              # Install AWS CLI (duplicate - you might want to remove this)
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              EOF

  tags = {
    Name = var.ec2_tag_name
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}