#!/bin/bash
set -e

# === Initial Logging Setup ===
mkdir -p /var/log
exec > >(tee /var/log/user-data.log) 2>&1
echo ">>> Starting EC2 provisioning at $(date)"

# === Fix DNS for EFS ===
echo ">>> Replacing /etc/resolv.conf to use AWS DNS for EFS resolution"
systemctl stop systemd-resolved || true
systemctl disable systemd-resolved || true
rm -f /etc/resolv.conf
echo "nameserver 169.254.169.253" > /etc/resolv.conf

# === Assign variables from Terraform ===
hostname="${hostname}"
AZ="${AZ}"
AWS_REGION="${AWS_REGION}"
efs1_dns_name="${efs1_dns_name}"
efs2_dns_name="${efs2_dns_name}"
efs3_dns_name="${efs3_dns_name}"

# === Fetch EC2 Metadata using IMDSv2 (optional fallback) ===
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
METADATA_BASE="http://169.254.169.254/latest/meta-data"
PUBLIC_IPV4=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/public-ipv4")


if [ -z "$AWS_REGION" ]; then
  AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/placement/availability-zone" | sed 's/[a-z]$//')
fi

export AZ AWS_REGION PUBLIC_IPV4 hostname

echo "EC2 is running in Availability Zone: $AZ"
echo "Derived AWS Region: $AWS_REGION"
echo "Public IP: $PUBLIC_IPV4"

# === Host Setup ===
hostnamectl set-hostname "$hostname"
echo "127.0.0.1   localhost $hostname" >> /etc/hosts
echo "export PS1='$hostname \$ '" >> /etc/bashrc
source /etc/bashrc

# === System Preparation ===
echo ">>> Installing required packages..."
dnf update -y
dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync vsftpd
runuser -l ssm-user -c 'npm install -g pm2'

# === Create EFS Mount Points ===
mkdir -p /mnt/efs/{code,data,logs}

# === Mount EFS Filesystems with Retry (TLS) ===
mount_efs_with_retry() {
  local dns_name="$1"
  local mount_point="$2"
  local max_retries=5
  local retry_count=0

  while [ $retry_count -lt $max_retries ]; do
    if mount -t efs -o tls "$dns_name:" "$mount_point"; then
      echo "SUCCESS: Mounted $dns_name to $mount_point"
      return 0
    else
      retry_count=$((retry_count + 1))
      echo "WARNING: Mount attempt $retry_count failed for $dns_name, retrying in 10 seconds..."
      sleep 10
    fi
  done

  echo "FAIL: Could not mount $dns_name after $max_retries attempts"
  return 1
}

echo ">>> Mounting EFS filesystems with TLS..."
mount_efs_with_retry "$efs1_dns_name" /mnt/efs/code
mount_efs_with_retry "$efs2_dns_name" /mnt/efs/data
mount_efs_with_retry "$efs3_dns_name" /mnt/efs/logs

# === Enable EFS Logging ===
exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
echo ">>> EFS logging now active at $(date)"

# === Permissions ===
chown -R ssm-user:ssm-user /mnt/efs/{logs,data,code}
chmod -R 755 /mnt/efs/{logs,data,code}

# === Persistent Mounts ===
cat >> /etc/fstab <<EOF
${efs1_dns_name}:/ /mnt/efs/code efs _netdev,tls 0 0
${efs2_dns_name}:/ /mnt/efs/data efs _netdev,tls 0 0
${efs3_dns_name}:/ /mnt/efs/logs efs _netdev,tls 0 0
EOF

echo ">>> fstab entries:"
grep amazonaws /etc/fstab || echo "No EFS entries found in fstab"

# === Application .env ===
mkdir -p /mnt/efs/code/nodejs-app
cat > /mnt/efs/code/nodejs-app/.env <<EOF
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
AWS_REGION=${AWS_REGION}
AVAILABILITY_ZONE=${AZ}
PUBLIC_IP=$PUBLIC_IPV4
HOSTNAME=${hostname}
LOG_FILE=/mnt/efs/logs/app-${hostname}.log
EOF

# === Log Rotation ===
cat > /etc/logrotate.d/nodejs-app <<EOF
/mnt/efs/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 644 ssm-user ssm-user
    sharedscripts
    postrotate
        /bin/systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

# === FTP Setup ===
cat >> /etc/vsftpd/vsftpd.conf <<EOF
local_root=/mnt/efs
chroot_local_user=YES
allow_writeable_chroot=YES
userlist_enable=YES
userlist_file=/etc/vsftpd/userlist
userlist_deny=NO
EOF

echo "ssm-user" >> /etc/vsftpd/userlist
systemctl enable vsftpd
systemctl start vsftpd

# === Final EFS Log File Setup ===
LOG_FILE="/mnt/efs/logs/app-${hostname}.log"
touch "$LOG_FILE"
chown ssm-user:ssm-user "$LOG_FILE"

# === Final Output ===
echo ">>> Final EFS mount status:"
df -h -t nfs4
echo ">>> EFS directories:"
ls -la /mnt/efs/

echo "EC2 provisioning completed successfully at $(date)"




