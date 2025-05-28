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


################# FTP #################
# === FTP Setup (vsftpd using EFS path) ===
yum install -y vsftpd

mkdir -p /mnt/efs/data/ftp
chown ec2-user:ec2-user /mnt/efs/data/ftp
usermod -d /mnt/efs/data/ftp ec2-user

cat >> /etc/vsftpd/vsftpd.conf <<EOF
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21050
pasv_address=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "0.0.0.0")
pasv_addr_resolve=YES
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
EOF

systemctl enable vsftpd
systemctl restart vsftpd
echo "✅ vsftpd installed and configured for /mnt/efs/data/ftp"


################# CloudWatch Logs Integration #################

echo ">>> Installing and configuring CloudWatch Agent"

yum install -y amazon-cloudwatch-agent

cat <<CWCONF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/mnt/efs/logs/*.log",
            "log_group_name": "/efs/app/logs",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
CWCONF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "✅ CloudWatch Agent configured and running"
