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

              # Create directories for EFS mounts
              echo ">>> Creating directories for EFS mounts..."
              sudo mkdir -p /mnt/efs/code
              sudo mkdir -p /mnt/efs/data
              sudo mkdir -p /mnt/efs/logs

              # Set proper permissions
              sudo chown ec2-user:ec2-user /mnt/efs/code /mnt/efs/data /mnt/efs/logs

              # Define EFS DNS names from Terraform interpolation
              EFS_CODE_DNS="${data.terraform_remote_state.efs.outputs.module_efs1_dns_name}"
              EFS_DATA_DNS="${data.terraform_remote_state.efs.outputs.module_efs2_dns_name}"
              EFS_LOGS_DNS="${data.terraform_remote_state.efs.outputs.module_efs3_dns_name}"

              echo ">>> EFS DNS Names:"
              echo "Code EFS: $EFS_CODE_DNS"
              echo "Data EFS: $EFS_DATA_DNS"
              echo "Logs EFS: $EFS_LOGS_DNS"

              # Check if EFS DNS names are valid
              if [[ -z "$EFS_CODE_DNS" || -z "$EFS_DATA_DNS" || -z "$EFS_LOGS_DNS" ]]; then
                  echo ">>> ERROR: One or more EFS DNS names are empty!"
                  echo ">>> Skipping EFS mount operations..."
                  exit 1
              fi

              #####################
              # EFS CLEARING FUNCTION - COMMENT OUT TO PRESERVE DATA
              #####################
              # Function to safely clear EFS content
              clear_efs_content() {
                  local mount_point=$1
                  local efs_name=$2
                  
                  echo ">>> Checking content in $efs_name EFS..."
                  if [ "$(sudo ls -A $mount_point 2>/dev/null)" ]; then
                      echo ">>> Found existing content in $efs_name EFS:"
                      sudo ls -la $mount_point
                      echo ">>> Clearing content from $efs_name EFS..."
                      sudo find $mount_point -mindepth 1 -delete 2>/dev/null || {
                          echo ">>> Using rm -rf as fallback for $efs_name..."
                          sudo rm -rf $mount_point/* $mount_point/.[!.]* 2>/dev/null || true
                      }
                      echo ">>> $efs_name EFS cleared successfully"
                  else
                      echo ">>> $efs_name EFS is already empty"
                  fi
              }
              #####################
              # END OF EFS CLEARING FUNCTION
              #####################

              #####################
              # EFS CONTENT DELETION SECTION - COMMENT OUT TO PRESERVE DATA
              #####################
              
              # Mount the EFS file systems temporarily to clear them
              echo ">>> Temporarily mounting EFS file systems to clear content..."
              
              # Create temporary mount points
              sudo mkdir -p /tmp/efs-temp/{code,data,logs}
              
              # Mount EFS temporarily
              echo ">>> Mounting Code EFS temporarily..."
              sudo mount -t efs -o tls,iam $EFS_CODE_DNS:/ /tmp/efs-temp/code
              if [ $? -eq 0 ]; then
                  clear_efs_content "/tmp/efs-temp/code" "Code"
                  sudo umount /tmp/efs-temp/code
              else
                  echo ">>> Failed to mount Code EFS temporarily"
              fi
              
              echo ">>> Mounting Data EFS temporarily..."
              sudo mount -t efs -o tls,iam $EFS_DATA_DNS:/ /tmp/efs-temp/data
              if [ $? -eq 0 ]; then
                  clear_efs_content "/tmp/efs-temp/data" "Data"
                  sudo umount /tmp/efs-temp/data
              else
                  echo ">>> Failed to mount Data EFS temporarily"
              fi
              
              echo ">>> Mounting Logs EFS temporarily..."
              sudo mount -t efs -o tls,iam $EFS_LOGS_DNS:/ /tmp/efs-temp/logs
              if [ $? -eq 0 ]; then
                  clear_efs_content "/tmp/efs-temp/logs" "Logs"
                  sudo umount /tmp/efs-temp/logs
              else
                  echo ">>> Failed to mount Logs EFS temporarily"
              fi
              
              # Remove temporary directories
              sudo rm -rf /tmp/efs-temp
              
              #####################
              # END OF EFS CONTENT DELETION SECTION
              #####################
              
              # Now mount EFS file systems to final locations
              echo ">>> Mounting EFS file systems to final locations..."
              sudo mount -t efs -o tls,iam $EFS_CODE_DNS:/ /mnt/efs/code
              if [ $? -eq 0 ]; then
                  echo ">>> Successfully mounted Code EFS"
                  echo ">>> Code EFS content after mounting:"
                  sudo ls -la /mnt/efs/code
              else
                  echo ">>> Failed to mount Code EFS"
              fi

              sudo mount -t efs -o tls,iam $EFS_DATA_DNS:/ /mnt/efs/data
              if [ $? -eq 0 ]; then
                  echo ">>> Successfully mounted Data EFS"
                  echo ">>> Data EFS content after mounting:"
                  sudo ls -la /mnt/efs/data
              else
                  echo ">>> Failed to mount Data EFS"
              fi

              sudo mount -t efs -o tls,iam $EFS_LOGS_DNS:/ /mnt/efs/logs
              if [ $? -eq 0 ]; then
                  echo ">>> Successfully mounted Logs EFS"
                  echo ">>> Logs EFS content after mounting:"
                  sudo ls -la /mnt/efs/logs
              else
                  echo ">>> Failed to mount Logs EFS"
              fi

              # Add EFS to fstab for persistence (only if mounts were successful)
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

              # Print current mounts
              echo ">>> Current EFS mounts:"
              mount | grep /mnt/efs

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