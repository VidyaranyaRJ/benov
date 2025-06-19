data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
}

data "terraform_remote_state" "efs" {
  backend = "s3"
  config = {
    bucket = "vj-test-benvolate"
    key    = "EFS/terraform.tfstate"
    region = "us-east-2"
  }
}


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

          # Log all output for debugging
          exec > >(tee /var/log/user-data.log)
          exec 2>&1

          echo ">>> Starting user data script execution..."
          date

          # Update packages
          echo ">>> Updating packages..."
          sudo yum update -y

          # Install required packages
          echo ">>> Installing packages..."
          sudo yum install -y nfs-utils curl unzip python3-pip

          # Install amazon-efs-utils for Amazon Linux 2023
          echo ">>> Installing amazon-efs-utils..."
          sudo yum install -y amazon-efs-utils || {
              echo ">>> amazon-efs-utils not available in repo, installing manually..."
              cd /tmp
              sudo yum install -y git make rpm-build
              git clone https://github.com/aws/efs-utils
              cd efs-utils
              make rpm
              sudo yum install -y ./build/amazon-efs-utils*rpm
          }

          # Set alias for python and pip
          echo ">>> Setting up Python aliases..."
          echo "alias python=python3" | sudo tee -a /etc/bashrc
          echo "alias pip=pip3" | sudo tee -a /etc/bashrc

          # Install AWS CLI
          echo ">>> Installing AWS CLI..."
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          sudo ./aws/install
          rm -rf aws awscliv2.zip

          # Create mount points (local folders — will be overwritten by EFS mounts)
          echo ">>> Creating directories for EFS mounts..."
          sudo mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs

          # Define EFS DNS names from Terraform
          EFS_CODE_DNS="${data.terraform_remote_state.efs.outputs.module_efs1_dns_name}"
          EFS_DATA_DNS="${data.terraform_remote_state.efs.outputs.module_efs2_dns_name}"
          EFS_LOGS_DNS="${data.terraform_remote_state.efs.outputs.module_efs3_dns_name}"

          echo ">>> EFS DNS Names:"
          echo "Code EFS: $EFS_CODE_DNS"
          echo "Data EFS: $EFS_DATA_DNS"
          echo "Logs EFS: $EFS_LOGS_DNS"

          # Validate EFS DNS entries
          if [[ -z "$EFS_CODE_DNS" || -z "$EFS_DATA_DNS" || -z "$EFS_LOGS_DNS" ]]; then
              echo ">>> ERROR: One or more EFS DNS names are empty!"
              exit 1
          fi

          # Mount EFS file systems
          echo ">>> Mounting EFS file systems..."
          sudo mount -t efs -o tls,iam $EFS_CODE_DNS:/ /mnt/efs/code
          sudo mount -t efs -o tls,iam $EFS_DATA_DNS:/ /mnt/efs/data
          sudo mount -t efs -o tls,iam $EFS_LOGS_DNS:/ /mnt/efs/logs

          # Log mount results
          echo ">>> Mounted directories:"
          mount | grep /mnt/efs

          # Add entries to fstab for persistence
          echo ">>> Adding EFS entries to /etc/fstab..."
          if mountpoint -q /mnt/efs/code; then
              echo "$EFS_CODE_DNS:/ /mnt/efs/code efs tls,iam,_netdev 0 0" | sudo tee -a /etc/fstab
          fi
          if mountpoint -q /mnt/efs/data; then
              echo "$EFS_DATA_DNS:/ /mnt/efs/data efs tls,iam,_netdev 0 0" | sudo tee -a /etc/fstab
          fi
          if mountpoint -q /mnt/efs/logs; then
              echo "$EFS_LOGS_DNS:/ /mnt/efs/logs efs tls,iam,_netdev 0 0" | sudo tee -a /etc/fstab
          fi

          # Fix permissions AFTER mounting EFS so ec2-user can write
          echo ">>> Fixing ownership of mounted EFS directories..."
          sudo chown -R ec2-user:ec2-user /mnt/efs/code /mnt/efs/data /mnt/efs/logs
          ls -ld /mnt/efs/code /mnt/efs/data /mnt/efs/logs

          # Set EC2 hostname using Terraform variable
          echo ">>> Setting hostname to $${var.hostname}..."
          sudo hostnamectl set-hostname "$${var.hostname}"
          echo "$${var.hostname}" | sudo tee /etc/hostname

          echo ">>> User data script completed!"
          date

        EOF

  tags = {
    Name = var.ec2_tag_name
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}