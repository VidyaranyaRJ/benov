#!/bin/bash


# # EC2 User Data script for Node.js app deployment using EFS and S3-based delivery

# hostnamectl set-hostname ${hostname}
# echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts

# # Modify the prompt to show the hostname
# echo "export PS1='$(hostname) \$ '" >> /etc/bashrc
# source /etc/bashrc

# # Ensure directories exist before logging
# mkdir -p /mnt/efs/logs

# exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
# echo ">>> Starting EC2 provisioning at $(date)"

# # === System Preparation ===
# sudo dnf update -y
# sudo dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync
# npm install -g pm2

# # === Create Mount Points ===
# mkdir -p /mnt/efs/{data,code,logs}

# # === Mount EFS using DNS names ===
# mount -t nfs4 -o nfsvers=4.1 ${efs1_dns_name}:/ /mnt/efs/code
# mount -t nfs4 -o nfsvers=4.1 ${efs2_dns_name}:/ /mnt/efs/data
# mount -t nfs4 -o nfsvers=4.1 ${efs3_dns_name}:/ /mnt/efs/logs

# # === Make EFS mounts persistent ===
# cat >> /etc/fstab <<EOF
# ${efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0
# ${efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0
# ${efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0
# EOF

# # === Permissions ===
# chmod 755 /mnt/efs/{code,data,logs}

# # === Setup App Directory ===
# mkdir -p /mnt/efs/code/nodejs-app

# # === .env Config ===
# cat > /mnt/efs/code/nodejs-app/.env <<EOF
# PORT=3000
# NODE_ENV=production
# LOG_PATH=/mnt/efs/logs
# DATA_PATH=/mnt/efs/data
# EOF

# # === Log Rotation ===
# cat > /etc/logrotate.d/nodejs-app <<EOF
# /mnt/efs/logs/*.log {
#     daily
#     missingok
#     rotate 14
#     compress
#     delaycompress
#     notifempty
#     create 0640 ec2-user ec2-user
# }
# EOF

# nohup node /mnt/efs/code/nodejs-app/index.js >> /var/log/node-app.log 2>&1 &


# echo ">>> EC2 provisioning completed at $(date)"




# # === Fetch EC2 Metadata using IMDSv2 ===
# TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
#   -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

# METADATA_BASE="http://169.254.169.254/latest/meta-data"
# PUBLIC_IPV4=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/public-ipv4")
# AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/placement/availability-zone")
# AWS_REGION=$(echo "$AZ" | sed 's/[a-z]$//')


# export AWS_REGION=$(echo "$AZ" | sed 's/[a-z]$//')

# ################# FTP #################
# # === FTP Setup (vsftpd using EFS path) ===
# sudo dnf install -y vsftpd

# mkdir -p /mnt/efs/data/ftp
# chown ec2-user:ec2-user /mnt/efs/data/ftp
# usermod -d /mnt/efs/data/ftp ec2-user

# cat >> /etc/vsftpd/vsftpd.conf <<EOF
# pasv_enable=YES
# pasv_min_port=21000
# pasv_max_port=21050



# pasv_addr_resolve=YES
# local_enable=YES
# write_enable=YES
# chroot_local_user=YES
# allow_writeable_chroot=YES
# EOF

# systemctl enable vsftpd
# systemctl restart vsftpd
# echo "✅ vsftpd installed and configured for /mnt/efs/data/ftp"








# set -e

# # === Logging Setup First ===
# mkdir -p /mnt/efs/logs
# exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
# echo ">>> Starting EC2 provisioning at $(date)"

# # === Fetch EC2 Metadata using IMDSv2 ===
# TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
#   -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# METADATA_BASE="http://169.254.169.254/latest/meta-data"
# AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/placement/availability-zone")
# PUBLIC_IPV4=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/public-ipv4")
# AWS_REGION=$(echo "$AZ" | sed 's/[a-z]$//')
# export AWS_REGION

# echo "AZ: ${AZ}"
# echo "AWS_REGION: ${AWS_REGION}"
# echo "PUBLIC_IP: $${PUBLIC_IPV4}"

# # === Host Setup ===
# hostnamectl set-hostname "${hostname}"
# echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts
# echo "export PS1='$(hostname) \$ '" >> /etc/bashrc
# source /etc/bashrc



# # === System Preparation ===
# dnf update -y
# dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync vsftpd
# npm install -g pm2

# # === Create and Mount EFS Directories ===
# mkdir -p /mnt/efs/{data,code,logs}
# mount -t nfs4 -o nfsvers=4.1 ${efs1_dns_name}:/ /mnt/efs/code
# mount -t nfs4 -o nfsvers=4.1 ${efs2_dns_name}:/ /mnt/efs/data
# mount -t nfs4 -o nfsvers=4.1 ${efs3_dns_name}:/ /mnt/efs/logs

# # === Make EFS mounts persistent ===
# cat >> /etc/fstab <<EOF
# ${efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0
# ${efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0
# ${efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0
# EOF

# # === Permissions ===
# chmod 755 /mnt/efs/{code,data,logs}

# # === Setup Node.js App ===
# mkdir -p /mnt/efs/code/nodejs-app
# cat > /mnt/efs/code/nodejs-app/.env <<EOF
# PORT=3000
# NODE_ENV=production
# LOG_PATH=/mnt/efs/logs
# DATA_PATH=/mnt/efs/data
# EOF

# # === Log Rotation Setup ===
# cat > /etc/logrotate.d/nodejs-app <<EOF
# /mnt/efs/logs/*.log {
#     daily
#     missingok
#     rotate 14
#     compress
#     delaycompress
#     notifempty
#     create 0640 ec2-user ec2-user
# }
# EOF

# # === Start Node.js App ===
# nohup node /mnt/efs/code/nodejs-app/index.js >> /var/log/node-app.log 2>&1 &

# echo "✅ Node.js app started successfully"
# echo ">>> EC2 provisioning completed at $(date)"

# # === FTP Setup (vsftpd using EFS path) ===
# mkdir -p /mnt/efs/data/ftp
# chown ec2-user:ec2-user /mnt/efs/data/ftp
# usermod -d /mnt/efs/data/ftp ec2-user

# cat >> /etc/vsftpd/vsftpd.conf <<EOF
# pasv_enable=YES
# pasv_min_port=21000
# pasv_max_port=21050
# pasv_address=$${PUBLIC_IPV4}
# pasv_addr_resolve=YES
# local_enable=YES
# write_enable=YES
# chroot_local_user=YES
# allow_writeable_chroot=YES
# EOF

# systemctl enable vsftpd
# systemctl restart vsftpd

# echo "✅ vsftpd installed and configured for /mnt/efs/data/ftp"




set -e

# === Logging Setup ===
mkdir -p /mnt/efs/logs
exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
echo ">>> Starting EC2 provisioning at $(date)"

# === Fetch EC2 Metadata using IMDSv2 ===
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

METADATA_BASE="http://169.254.169.254/latest/meta-data"
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/placement/availability-zone")
PUBLIC_IPV4=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/public-ipv4")
AWS_REGION=$(echo "$AZ" | sed 's/[a-z]$//')

export AZ
export AWS_REGION
export PUBLIC_IPV4

echo "✅ EC2 is running in Availability Zone: $AZ"
echo "✅ Derived AWS Region: $AWS_REGION"
echo "✅ Public IP: $PUBLIC_IPV4"

# === Host Setup ===
hostnamectl set-hostname "${hostname}"
echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts
echo "export PS1='$(hostname) \$ '" >> /etc/bashrc
source /etc/bashrc

# === System Preparation ===
dnf update -y
dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync vsftpd
npm install -g pm2

# === Create and Mount EFS Directories ===
mkdir -p /mnt/efs/{data,code,logs}
mount -t nfs4 -o nfsvers=4.1 ${efs1_dns_name}:/ /mnt/efs/code
mount -t nfs4 -o nfsvers=4.1 ${efs2_dns_name}:/ /mnt/efs/data
mount -t nfs4 -o nfsvers=4.1 ${efs3_dns_name}:/ /mnt/efs/logs

# === Make EFS mounts persistent ===
cat >> /etc/fstab <<EOF
${efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0
${efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0
${efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0
EOF

# === Permissions ===
chmod 755 /mnt/efs/{code,data,logs}

# === Setup Node.js App ===
mkdir -p /mnt/efs/code/nodejs-app
cat > /mnt/efs/code/nodejs-app/.env <<EOF
PORT=3000
NODE_ENV=production
LOG_PATH=/mnt/efs/logs
DATA_PATH=/mnt/efs/data
EOF

# === Log Rotation Setup ===
cat > /etc/logrotate.d/nodejs-app <<EOF
/mnt/efs/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ec2-user ec2-user
}
EOF

# === Start Node.js App ===
nohup node /mnt/efs/code/nodejs-app/index.js >> /var/log/node-app.log 2>&1 &
echo "✅ Node.js app started successfully"

# === FTP Setup ===
mkdir -p /mnt/efs/data/ftp
chown ec2-user:ec2-user /mnt/efs/data/ftp
usermod -d /mnt/efs/data/ftp ec2-user

cat >> /etc/vsftpd/vsftpd.conf <<EOF
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21050
pasv_address=${PUBLIC_IPV4}
pasv_addr_resolve=YES
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
EOF

systemctl enable vsftpd
systemctl restart vsftpd
echo "✅ vsftpd installed and configured for /mnt/efs/data/ftp"

echo ">>> EC2 provisioning completed at $(date)"
