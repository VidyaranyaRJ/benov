#!/bin/bash



# set -e

# # === Logging Setup ===
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

# export AZ
# export AWS_REGION
# export PUBLIC_IPV4

# echo "✅ EC2 is running in Availability Zone: $AZ"
# echo "✅ Derived AWS Region: $AWS_REGION"
# echo "✅ Public IP: $PUBLIC_IPV4"

# # === Host Setup ===
# hostnamectl set-hostname "${hostname}"
# echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts
# echo "export PS1='$(hostname) \$ '" >> /etc/bashrc
# source /etc/bashrc

# # === System Preparation ===
# dnf update -y
# dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync vsftpd
# runuser -l ssm-user -c 'npm install -g pm2'

# # === Create and Mount EFS Directories ===
# mkdir -p /mnt/efs/{code,data,logs}
# mount -t nfs4 -o nfsvers=4.1 ${efs1_dns_name}:/ /mnt/efs/code
# mount -t nfs4 -o nfsvers=4.1 ${efs2_dns_name}:/ /mnt/efs/data
# mount -t nfs4 -o nfsvers=4.1 ${efs3_dns_name}:/ /mnt/efs/logs

# # === Fix permissions for app logging ===
# chown -R ssm-user:ssm-user /mnt/efs/{logs,data,code}
# chmod -R 755 /mnt/efs/{logs,data,code}

# # === Make EFS mounts persistent ===
# cat >> /etc/fstab <<EOF
# ${efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0
# ${efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0
# ${efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0
# EOF

# # === Create default .env file ===
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
#     create 0640 ssm-user ssm-user
# }
# EOF

# # === FTP Setup ===
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

# # === Create daily log file with proper permissions ===
# TODAY=$(date +%m-%d-%Y)
# LOG_DIR="/mnt/efs/logs/$TODAY/$hostname"
# LOG_FILE="$LOG_DIR/node-app.log"

# mkdir -p "$LOG_DIR"
# touch "$LOG_FILE"
# chown ssm-user:ssm-user "$LOG_FILE"
# chmod 644 "$LOG_FILE"

# # Inject log file path into .env
# echo "APP_LOG_FILE=$LOG_FILE" >> /mnt/efs/code/nodejs-app/.env
# echo "✅ Log file prepared at $LOG_FILE"

# echo ">>> EC2 provisioning completed at $(date)"

##running for one instance ####

#!/bin/bash
# set -e

# # === Initial Logging Setup ===
# mkdir -p /var/log
# exec > >(tee /var/log/user-data.log) 2>&1
# echo ">>> Starting EC2 provisioning at $(date)"

# # === Assign variables from Terraform ===
# hostname="${hostname}"
# AZ="${AZ}"
# AWS_REGION="${AWS_REGION}"
# efs1_dns_name="${efs1_dns_name}"
# efs2_dns_name="${efs2_dns_name}"
# efs3_dns_name="${efs3_dns_name}"

# # === Fetch EC2 Metadata using IMDSv2 (optional, can use from Terraform) ===
# TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# METADATA_BASE="http://169.254.169.254/latest/meta-data"
# PUBLIC_IPV4=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/public-ipv4")

# if [ -z "$AWS_REGION" ]; then
#   AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_BASE/placement/availability-zone" | sed 's/[a-z]$//')
# fi

# export AZ AWS_REGION PUBLIC_IPV4 hostname

# echo "EC2 is running in Availability Zone: $AZ"
# echo "Derived AWS Region: $AWS_REGION"
# echo "Public IP: $PUBLIC_IPV4"

# # === Host Setup ===
# hostnamectl set-hostname "$hostname"
# echo "127.0.0.1   localhost $hostname" >> /etc/hosts
# echo "export PS1='$hostname \$ '" >> /etc/bashrc
# source /etc/bashrc

# # === System Preparation ===
# echo ">>> Installing required packages..."
# dnf update -y
# dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync vsftpd
# runuser -l ssm-user -c 'npm install -g pm2'

# # === Create EFS Mount Points ===
# mkdir -p /mnt/efs/{code,data,logs}

# # === Mount EFS Filesystems with Retry ===
# mount_efs_with_retry() {
#   local dns_name="$1"
#   local mount_point="$2"
#   local max_retries=5
#   local retry_count=0

#   while [ $retry_count -lt $max_retries ]; do
#     if mount -t nfs4 -o nfsvers=4.1,tls "$${dns_name}:/" "$${mount_point}"; then
#       echo "SUCCESS: Successfully mounted $dns_name to $mount_point"
#       return 0
#     else
#       retry_count=$((retry_count + 1))
#       echo "WARNING: Mount attempt $retry_count failed for $dns_name, retrying in 10 seconds..."
#       sleep 10
#     fi
#   done

#   echo "FAIL: Failed to mount $dns_name after $max_retries attempts"
#   return 1
# }

# echo ">>> Mounting EFS filesystems..."
# mount_efs_with_retry "$efs1_dns_name" /mnt/efs/code
# mount_efs_with_retry "$efs2_dns_name" /mnt/efs/data
# mount_efs_with_retry "$efs3_dns_name" /mnt/efs/logs

# # === Verify Mounts ===
# df -h -t nfs4 || echo "No NFS mounts found"
# mount | grep nfs4 || echo "No NFS4 entries in mount"

# # === Enable EFS Logging ===
# exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
# echo ">>> EFS logging now active at $(date)"

# # === Fix permissions ===
# chown -R ssm-user:ssm-user /mnt/efs/{logs,data,code}
# chmod -R 755 /mnt/efs/{logs,data,code}

# # === Add persistent mounts ===
# cat >> /etc/fstab <<EOF
# ${efs1_dns_name}:/ /mnt/efs/code nfs4 nfsvers=4.1,_netdev,tls 0 0
# ${efs2_dns_name}:/ /mnt/efs/data nfs4 nfsvers=4.1,_netdev,tls 0 0
# ${efs3_dns_name}:/ /mnt/efs/logs nfs4 nfsvers=4.1,_netdev,tls 0 0
# EOF

# echo ">>> fstab entries:"
# grep amazonaws /etc/fstab || echo "No EFS entries found in fstab"

# # === Application environment ===
# mkdir -p /mnt/efs/code/nodejs-app
# cat > /mnt/efs/code/nodejs-app/.env <<EOF
# NODE_ENV=production
# PORT=3000
# LOG_LEVEL=info
# AWS_REGION=${AWS_REGION}
# AVAILABILITY_ZONE=${AZ}
# PUBLIC_IP=$${PUBLIC_IPV4}
# HOSTNAME=${hostname}
# LOG_FILE=/mnt/efs/logs/app-${hostname}.log
# EOF

# # === Setup log rotation ===
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

# # === Configure FTP ===
# cat >> /etc/vsftpd/vsftpd.conf <<EOF
# local_root=/mnt/efs
# chroot_local_user=YES
# allow_writeable_chroot=YES
# userlist_enable=YES
# userlist_file=/etc/vsftpd/userlist
# userlist_deny=NO
# EOF

# echo "ssm-user" >> /etc/vsftpd/userlist
# systemctl enable vsftpd
# systemctl start vsftpd

# # === Final Log File Setup ===
# LOG_FILE="/mnt/efs/logs/app-${hostname}.log"
# touch "$LOG_FILE"
# chown ssm-user:ssm-user "$LOG_FILE"

# # === Final Output ===
# echo ">>> Final EFS mount status:"
# df -h -t nfs4
# echo ">>> EFS directories:"
# ls -la /mnt/efs/

# echo "EC2 provisioning completed successfully at $(date)"



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

