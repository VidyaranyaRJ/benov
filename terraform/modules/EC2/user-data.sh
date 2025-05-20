#!/bin/bash
# EC2 User Data script for Node.js app deployment using EFS and S3-based delivery

hostnamectl set-hostname ${hostname}
echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts


exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
echo ">>> Starting EC2 provisioning at $(date)"

# === System Preparation ===
yum update -y
yum install -y amazon-efs-utils nfs-utils nodejs npm rsync -y
npm install -g pm2

# === Create Mount Points ===
mkdir -p /mnt/efs/{data,code,logs}

# === Mount EFS using DNS names ===
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

# === Setup App Directory ===
mkdir -p /mnt/efs/code/nodejs-app

# === .env Config ===
cat > /mnt/efs/code/nodejs-app/.env <<EOF
PORT=3000
NODE_ENV=production
LOG_PATH=/mnt/efs/logs
DATA_PATH=/mnt/efs/data
EOF

# === Log Rotation ===
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

echo ">>> EC2 provisioning completed at $(date)"
