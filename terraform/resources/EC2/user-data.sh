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
# pasv_address=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "0.0.0.0")
# pasv_addr_resolve=YES
# local_enable=YES
# write_enable=YES
# chroot_local_user=YES
# allow_writeable_chroot=YES
# EOF

# systemctl enable vsftpd
# systemctl restart vsftpd
# echo "✅ vsftpd installed and configured for /mnt/efs/data/ftp"




hostnamectl set-hostname ${hostname}
echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts
echo "export PS1='$(hostname) \$ '" >> /etc/bashrc
source /etc/bashrc

exec > >(tee /var/log/user-data.log) 2>&1
echo ">>> Starting EC2 provisioning at $(date)"

# === System Preparation ===
sudo dnf update -y
sudo dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync
npm install -g pm2

# === Create Mount Points ===
mkdir -p /mnt/efs/{data,code,logs}

# === Mount EFS Code and Data (no access point needed if root-only) ===
mount -t nfs4 -o nfsvers=4.1 ${efs1_dns_name}:/ /mnt/efs/code
mount -t nfs4 -o nfsvers=4.1 ${efs2_dns_name}:/ /mnt/efs/data

# === Mount EFS Logs Using Access Point ===
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs3_dns_name}:/${efs_logs_access_point_id} /mnt/efs/logs

# === Make EFS Mounts Persistent ===
cat >> /etc/fstab <<EOF
${efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0
${efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0
${efs3_dns_name}:/${efs_logs_access_point_id} /mnt/efs/logs nfs4 defaults,_netdev 0 0
EOF

# === Set Permissions ===
chown ssm-user:ssm-user /mnt/efs/logs
chmod 755 /mnt/efs/logs

# === .env Config ===
cat > /mnt/efs/code/nodejs-app/.env <<EOF
PORT=3000
NODE_ENV=production
LOG_PATH=/mnt/efs/logs
DATA_PATH=/mnt/efs/data
EOF

# === Start App as ssm-user ===
cd /mnt/efs/code/nodejs-app
sudo -u ssm-user node index.js >> /mnt/efs/logs/node-app.log 2>&1 &

echo ">>> EC2 provisioning completed at $(date)"
