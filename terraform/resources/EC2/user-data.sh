#!/bin/bash
# set -e

# # === Initial Logging Setup ===
# mkdir -p /var/log
# exec > >(tee /var/log/user-data.log) 2>&1
# echo ">>> Starting EC2 provisioning at $(date)"

# # === Fix DNS for EFS ===
# echo ">>> Replacing /etc/resolv.conf to use AWS DNS for EFS resolution"
# systemctl stop systemd-resolved || true
# systemctl disable systemd-resolved || true
# rm -f /etc/resolv.conf
# echo "nameserver 169.254.169.253" > /etc/resolv.conf

# # === Assign variables from Terraform ===
# hostname="${hostname}"
# AZ="${AZ}"
# AWS_REGION="${AWS_REGION}"
# efs1_dns_name="${efs1_dns_name}"
# efs2_dns_name="${efs2_dns_name}"
# efs3_dns_name="${efs3_dns_name}"

# # === System Preparation ===
# echo ">>> Installing required packages..."
# dnf update -y
# dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync

# # === Create EFS Mount Points ===
# echo ">>> Creating EFS mount points..."
# mkdir -p /mnt/efs/{code,data,logs}

# # === Mount EFS Filesystems with Retry (TLS) ===
# mount_efs_with_retry() {
#   local dns_name="$1"
#   local mount_point="$2"
#   local max_retries=5
#   local retry_count=0

#   while [ $retry_count -lt $max_retries ]; do
#     if mount -t efs -o tls "$dns_name:" "$mount_point"; then
#       echo "SUCCESS: Mounted $dns_name to $mount_point"
#       return 0
#     else
#       retry_count=$((retry_count + 1))
#       echo "WARNING: Mount attempt $retry_count failed for $dns_name, retrying in 10 seconds..."
#       sleep 10
#     fi
#   done

#   echo "FAIL: Could not mount $dns_name after $max_retries attempts"
#   return 1
# }

# echo ">>> Mounting EFS filesystems with TLS..."
# mount_efs_with_retry "$efs1_dns_name" /mnt/efs/code
# mount_efs_with_retry "$efs2_dns_name" /mnt/efs/data
# mount_efs_with_retry "$efs3_dns_name" /mnt/efs/logs

# # === Persistent Mounts ===
# echo ">>> Adding EFS to /etc/fstab for persistence..."
# cat >> /etc/fstab <<EOF
# ${efs1_dns_name}:/ /mnt/efs/code efs _netdev,tls 0 0
# ${efs2_dns_name}:/ /mnt/efs/data efs _netdev,tls 0 0
# ${efs3_dns_name}:/ /mnt/efs/logs efs _netdev,tls 0 0
# EOF

# # === Setup App Environment ===
# mkdir -p /mnt/efs/code/nodejs-app
# cat > /mnt/efs/code/nodejs-app/.env <<EOF
# NODE_ENV=production
# PORT=3000
# LOG_LEVEL=info
# AWS_REGION=${AWS_REGION}
# AVAILABILITY_ZONE=${AZ}
# PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
# HOSTNAME=${hostname}
# LOG_FILE=/mnt/efs/logs/$(date +%Y-%m-%d)/app-${hostname}.log
# EOF

# # === Create Log Directory for Today ===
# today_date=$(date +%Y-%m-%d)
# mkdir -p "/mnt/efs/logs/$today_date"

# # === Permissions Setup ===
# echo ">>> Setting up permissions for EFS directories..."
# chown -R ssm-user:ssm-user /mnt/efs/{logs,data,code}
# chmod -R 755 /mnt/efs/{logs,data,code}

# # === Log Rotation ===
# echo ">>> Configuring log rotation for Node.js app..."
# cat > /etc/logrotate.d/nodejs-app <<EOF
# /mnt/efs/logs/*.log {
#     daily
#     missingok
#     rotate 30
#     compress
#     notifempty
#     create 644 ssm-user ssm-user
#     sharedscripts
#     postrotate
#         /bin/systemctl reload rsyslog > /dev/null 2>&1 || true
#     endscript
# }
# EOF

# # === Final EFS Log File Setup ===
# LOG_FILE="/mnt/efs/logs/$today_date/app-${hostname}.log"
# touch "$LOG_FILE"
# chown ssm-user:ssm-user "$LOG_FILE"

# # === Final Output ===
# echo ">>> Final EFS mount status:"
# df -h -t nfs4
# echo ">>> EFS directories:"
# ls -la /mnt/efs/

# echo "EC2 provisioning completed successfully at $(date)"



#!/bin/bash



# set -e

# # === Initial Logging Setup ===
# mkdir -p /var/log
# exec > >(tee /var/log/user-data.log) 2>&1
# echo ">>> Starting EC2 provisioning at $(date)"

# # === Fix DNS for EFS ===
# echo ">>> Replacing /etc/resolv.conf to use AWS DNS for EFS resolution"
# systemctl stop systemd-resolved || true
# systemctl disable systemd-resolved || true
# rm -f /etc/resolv.conf
# echo "nameserver 169.254.169.253" > /etc/resolv.conf

# # === Assign variables from Terraform ===
# hostname="${hostname}"
# AZ="${AZ}"
# AWS_REGION="${AWS_REGION}"
# efs1_dns_name="${efs1_dns_name}"
# efs2_dns_name="${efs2_dns_name}"
# efs3_dns_name="${efs3_dns_name}"

# # === SSH Key Download from S3 ===
# echo "📥 Downloading SSH key from S3..."
# SSH_S3_PATH="s3://$TF_STATE_BUCKET/EC2/vj-Benevolate.pem"

# if ! aws s3 cp "$SSH_S3_PATH" "/home/ec2-user/vj-Benevolate.pem" --region "$AWS_REGION"; then
#     echo "❌ SSH key not found in S3 at $SSH_S3_PATH"
#     exit 1
# fi

# chmod 400 "/home/ec2-user/vj-Benevolate.pem"
# echo "✅ SSH key downloaded from S3 and permissions set"

# # === System Preparation ===
# echo ">>> Installing required packages..."
# dnf update -y
# dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync

# # === Create EFS Mount Points ===
# echo ">>> Creating EFS mount points..."
# mkdir -p /mnt/efs/{code,data,logs}

# # === Mount EFS Filesystems with Retry (TLS) ===
# mount_efs_with_retry() {
#   local dns_name="$1"
#   local mount_point="$2"
#   local max_retries=5
#   local retry_count=0

#   while [ $retry_count -lt $max_retries ]; do
#     if mount -t efs -o tls "$dns_name:" "$mount_point"; then
#       echo "SUCCESS: Mounted $dns_name to $mount_point"
#       return 0
#     else
#       retry_count=$((retry_count + 1))
#       echo "WARNING: Mount attempt $retry_count failed for $dns_name, retrying in 10 seconds..."
#       sleep 10
#     fi
#   done

#   echo "FAIL: Could not mount $dns_name after $max_retries attempts"
#   return 1
# }

# echo ">>> Mounting EFS filesystems with TLS..."
# mount_efs_with_retry "$efs1_dns_name" /mnt/efs/code
# mount_efs_with_retry "$efs2_dns_name" /mnt/efs/data
# mount_efs_with_retry "$efs3_dns_name" /mnt/efs/logs

# # === Persistent Mounts ===
# echo ">>> Adding EFS to /etc/fstab for persistence..."
# cat >> /etc/fstab <<EOF
# ${efs1_dns_name}:/ /mnt/efs/code efs _netdev,tls 0 0
# ${efs2_dns_name}:/ /mnt/efs/data efs _netdev,tls 0 0
# ${efs3_dns_name}:/ /mnt/efs/logs efs _netdev,tls 0 0
# EOF

# # === Setup App Environment ===
# mkdir -p /mnt/efs/code/nodejs-app
# cat > /mnt/efs/code/nodejs-app/.env <<EOF
# NODE_ENV=production
# PORT=3000
# LOG_LEVEL=info
# AWS_REGION=${AWS_REGION}
# AVAILABILITY_ZONE=${AZ}
# PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
# HOSTNAME=${hostname}
# LOG_FILE=/mnt/efs/logs/$(date +%Y-%m-%d)/app-${hostname}.log
# EOF

# # === Create Log Directory for Today ===
# today_date=$(date +%Y-%m-%d)
# mkdir -p "/mnt/efs/logs/$today_date"

# # === Permissions Setup ===
# echo ">>> Setting up permissions for EFS directories..."
# chown -R ssm-user:ssm-user /mnt/efs/{logs,data,code}
# chmod -R 755 /mnt/efs/{logs,data,code}

# # === Log Rotation ===
# echo ">>> Configuring log rotation for Node.js app..."
# cat > /etc/logrotate.d/nodejs-app <<EOF
# /mnt/efs/logs/*.log {
#     daily
#     missingok
#     rotate 30
#     compress
#     notifempty
#     create 644 ssm-user ssm-user
#     sharedscripts
#     postrotate
#         /bin/systemctl reload rsyslog > /dev/null 2>&1 || true
#     endscript
# }
# EOF

# # === Final EFS Log File Setup ===
# LOG_FILE="/mnt/efs/logs/$today_date/app-${hostname}.log"
# touch "$LOG_FILE"
# chown ssm-user:ssm-user "$LOG_FILE"

# # === Final Output ===
# echo ">>> Final EFS mount status:"
# df -h -t nfs4
# echo ">>> EFS directories:"
# ls -la /mnt/efs/

# echo "EC2 provisioning completed successfully at $(date)"






#!/bin/bash

# Update packages
sudo apt-get update -y
sudo apt-get install -y nfs-common git binutils python3-pip curl unzip
sudo pip3 install botocore

# Set alias for python and pip
echo "alias python=python3" | sudo tee -a /etc/bash.bashrc
echo "alias pip=pip3" | sudo tee -a /etc/bash.bashrc

# Mount EFS
sudo mkdir -p /mnt/efs/code
sudo mkdir -p /mnt/efs/data
sudo mkdir -p /mnt/efs/logs

# Clone EFS utils repository
git clone https://github.com/aws/efs-utils
cd ./efs-utils

# Build and install EFS utilities
sudo ./build-deb.sh
sudo apt-get install -y ./build/amazon-efs-utils*deb

# Mount the EFS filesystems
echo ">>> Mounting EFS filesystems..."

# Mount EFS1 (Code)
sudo mount -t efs -o tls,iam ${aws_efs_file_system.code.id}:/ /mnt/efs/code

# Mount EFS2 (Data)
sudo mount -t efs -o tls,iam ${aws_efs_file_system.data.id}:/ /mnt/efs/data

# Mount EFS3 (Logs)
sudo mount -t efs -o tls,iam ${aws_efs_file_system.logs.id}:/ /mnt/efs/logs

# Add EFS to fstab for persistence
echo '${aws_efs_file_system.code.id}:/ /mnt/efs/code efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
echo '${aws_efs_file_system.data.id}:/ /mnt/efs/data efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
echo '${aws_efs_file_system.logs.id}:/ /mnt/efs/logs efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
