#!/bin/bash
# EC2 User Data script for Node.js app deployment using EFS and S3-based delivery

# hostnamectl set-hostname ${hostname}
# echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts

# # Modify the prompt to show the hostname
# echo "export PS1='$(hostname) \$ '" >> /etc/bashrc
# source /etc/bashrc

# exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
# echo ">>> Starting EC2 provisioning at $(date)"

# # === System Preparation ===
# yum update -y
# yum install -y amazon-efs-utils nfs-utils nodejs npm rsync -y
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

# echo ">>> EC2 provisioning completed at $(date)"


# ################# FTP #################
# # === FTP Setup (vsftpd using EFS path) ===
# yum install -y vsftpd

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


# ################# CloudWatch Logs Integration #################

# echo ">>> Installing and configuring CloudWatch Agent"

# yum install -y amazon-cloudwatch-agent

#   # === Generate dynamic log stream name ===
#   INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
#   REGION="us-east-2"

#   echo ">>> EC2 Instance Region: $REGION"

#   # Install jq if missing
#   yum install -y jq aws-cli

#   INSTANCE_NAME=$(aws ec2 describe-tags \
#     --region "$REGION" \
#     --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
#     --query "Tags[0].Value" --output text)

#   LOG_STREAM_NAME="$${INSTANCE_NAME:-unnamed}-$${INSTANCE_ID}"

#   # === CloudWatch Agent Config ===
#   cat <<CWCONF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
#   {
#     "logs": {
#       "logs_collected": {
#         "files": {
#           "collect_list": [
#             {
#               "file_path": "/mnt/efs/logs/*.log",
#               "log_group_name": "/efs/app/logs",
#               "log_stream_name": "$LOG_STREAM_NAME",
#               "timestamp_format": "%Y-%m-%d %H:%M:%S"
#             }
#           ]
#         }
#       }
#     },
#     "region": "us-east-2"
# }
# CWCONF


# /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#   -a fetch-config \
#   -m ec2 \
#   -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
#   -s

# echo "✅ CloudWatch Agent configured and running"




# EC2 User Data script for Node.js app deployment using EFS and S3-based delivery

# Set hostname and logging
hostnamectl set-hostname ${hostname}
echo "127.0.0.1   localhost ${hostname}" >> /etc/hosts

# Modify the prompt to show the hostname
echo "export PS1='$(hostname) \$ '" >> /etc/bashrc

# Create log directory early
mkdir -p /var/log/userdata
exec > >(tee /var/log/userdata/init.log) 2>&1

echo ">>> Starting EC2 provisioning at $(date)"

# === System Preparation ===
echo ">>> Updating system packages"
dnf update -y

echo ">>> Installing base packages"
dnf install -y amazon-efs-utils nfs-utils nodejs npm rsync

echo ">>> Installing PM2 globally"
npm install -g pm2

# === Create Mount Points ===
echo ">>> Creating EFS mount points"
mkdir -p /mnt/efs/{data,code,logs}

# === Mount EFS using DNS names ===
echo ">>> Mounting EFS filesystems"
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2 ${efs1_dns_name}:/ /mnt/efs/code
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2 ${efs2_dns_name}:/ /mnt/efs/data
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2 ${efs3_dns_name}:/ /mnt/efs/logs

# === Make EFS mounts persistent ===
echo ">>> Adding EFS mounts to /etc/fstab"
cat >> /etc/fstab <<EOF
${efs1_dns_name}:/ /mnt/efs/code nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2,_netdev 0 0
${efs2_dns_name}:/ /mnt/efs/data nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2,_netdev 0 0
${efs3_dns_name}:/ /mnt/efs/logs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2,_netdev 0 0
EOF

# === Set Permissions ===
echo ">>> Setting EFS permissions"
chmod 755 /mnt/efs/{code,data,logs}
chown ec2-user:ec2-user /mnt/efs/{code,data,logs}

# === Setup App Directory ===
echo ">>> Setting up application directory"
mkdir -p /mnt/efs/code/nodejs-app
chown -R ec2-user:ec2-user /mnt/efs/code/nodejs-app

# === .env Config ===
echo ">>> Creating application .env file"
cat > /mnt/efs/code/nodejs-app/.env <<EOF
PORT=3000
NODE_ENV=production
LOG_PATH=/mnt/efs/logs
DATA_PATH=/mnt/efs/data
EOF

chown ec2-user:ec2-user /mnt/efs/code/nodejs-app/.env

# === Log Rotation ===
echo ">>> Setting up log rotation"
cat > /etc/logrotate.d/nodejs-app <<EOF
/mnt/efs/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ec2-user ec2-user
    sharedscripts
    postrotate
        # Restart or reload your app if needed
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

################# FTP Setup #################
echo ">>> Setting up FTP server"
dnf install -y vsftpd

mkdir -p /mnt/efs/data/ftp
chown ec2-user:ec2-user /mnt/efs/data/ftp
chmod 755 /mnt/efs/data/ftp

# Get public IP for PASV mode
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "127.0.0.1")

# Configure vsftpd
cat > /etc/vsftpd/vsftpd.conf <<EOF
# Basic Settings
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

# Security Settings
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES

# Passive Mode Settings
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21010
pasv_address=$PUBLIC_IP
pasv_addr_resolve=NO

# Logging
xferlog_file=/var/log/vsftpd.log
log_ftp_protocol=YES

# Performance
idle_session_timeout=600
data_connection_timeout=120
EOF

# Ensure vsftpd user list allows ec2-user
echo "ec2-user" >> /etc/vsftpd/user_list

# Start and enable vsftpd
systemctl enable vsftpd
systemctl start vsftpd

echo "✅ vsftpd installed and configured for /mnt/efs/data/ftp"

################# CloudWatch Logs Integration #################
echo ">>> Installing and configuring CloudWatch Agent"

# Install CloudWatch agent
dnf install -y amazon-cloudwatch-agent

# Install additional tools
dnf install -y jq awscli

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-2")

echo ">>> Instance ID: $INSTANCE_ID, Region: $REGION"

# Get instance name from tags (with error handling)
INSTANCE_NAME=""
if command -v aws >/dev/null 2>&1; then
    INSTANCE_NAME=$(aws ec2 describe-tags \
        --region "$REGION" \
        --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
        --query "Tags[0].Value" \
        --output text 2>/dev/null || echo "")
fi

# Fallback if name retrieval fails
if [ "$INSTANCE_NAME" = "None" ] || [ -z "$INSTANCE_NAME" ]; then
    INSTANCE_NAME="ec2-instance"
fi

LOG_STREAM_NAME="${INSTANCE_NAME}-${INSTANCE_ID}"

echo ">>> Using log stream name: $LOG_STREAM_NAME"

# Create CloudWatch agent configuration
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWCONF
{
    "agent": {
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/mnt/efs/logs/app.log",
                        "log_group_name": "/efs/nodejs-app/logs",
                        "log_stream_name": "$LOG_STREAM_NAME-app",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/mnt/efs/logs/error.log",
                        "log_group_name": "/efs/nodejs-app/errors",
                        "log_stream_name": "$LOG_STREAM_NAME-error",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/userdata/init.log",
                        "log_group_name": "/ec2/userdata",
                        "log_stream_name": "$LOG_STREAM_NAME-init",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "EFS/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
CWCONF

echo ">>> Starting CloudWatch agent"

# Start the CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Enable CloudWatch agent service
systemctl enable amazon-cloudwatch-agent

# Verify CloudWatch agent status
sleep 5
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "✅ CloudWatch Agent is running successfully"
else
    echo "❌ CloudWatch Agent failed to start"
    systemctl status amazon-cloudwatch-agent
fi

################# Setup Sample App #################
echo ">>> Setting up sample Node.js application"

# Create a sample app if none exists
if [ ! -f /mnt/efs/code/nodejs-app/package.json ]; then
    cat > /mnt/efs/code/nodejs-app/package.json <<EOF
{
  "name": "efs-nodejs-app",
  "version": "1.0.0",
  "description": "Sample Node.js app running on EFS",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "winston": "^3.8.2"
  }
}
EOF

    cat > /mnt/efs/code/nodejs-app/app.js <<EOF
const express = require('express');
const winston = require('winston');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Ensure log directory exists
const logDir = process.env.LOG_PATH || '/mnt/efs/logs';
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

// Configure Winston logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: path.join(logDir, 'error.log'), level: 'error' }),
        new winston.transports.File({ filename: path.join(logDir, 'app.log') }),
        new winston.transports.Console()
    ]
});

app.use(express.json());

app.get('/', (req, res) => {
    logger.info('Root endpoint accessed', { 
        ip: req.ip, 
        userAgent: req.get('User-Agent') 
    });
    res.json({ 
        message: 'Hello from EFS-backed Node.js app!', 
        timestamp: new Date().toISOString(),
        hostname: require('os').hostname()
    });
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.listen(PORT, '0.0.0.0', () => {
    logger.info(\`Server started on port \${PORT}\`);
});
EOF

    chown -R ec2-user:ec2-user /mnt/efs/code/nodejs-app
fi

################# PM2 Setup #################
echo ">>> Setting up PM2 process manager"

# Create PM2 ecosystem file
cat > /mnt/efs/code/nodejs-app/ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'efs-nodejs-app',
    script: './app.js',
    cwd: '/mnt/efs/code/nodejs-app',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    log_file: '/mnt/efs/logs/pm2-combined.log',
    out_file: '/mnt/efs/logs/pm2-out.log',
    error_file: '/mnt/efs/logs/pm2-error.log',
    time: true
  }]
};
EOF

chown ec2-user:ec2-user /mnt/efs/code/nodejs-app/ecosystem.config.js

# Install app dependencies as ec2-user
cd /mnt/efs/code/nodejs-app
sudo -u ec2-user npm install

# Setup PM2 startup script
sudo -u ec2-user pm2 startup systemd -u ec2-user --hp /home/ec2-user
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user --service-name pm2-ec2-user

echo ">>> EC2 provisioning completed successfully at $(date)"
echo ">>> Services status:"
systemctl is-active vsftpd && echo "✅ vsftpd: Active" || echo "❌ vsftpd: Failed"
systemctl is-active amazon-cloudwatch-agent && echo "✅ CloudWatch Agent: Active" || echo "❌ CloudWatch Agent: Failed"

echo ">>> To start the Node.js app, run as ec2-user:"
echo "cd /mnt/efs/code/nodejs-app && pm2 start ecosystem.config.js"

# Final verification
echo ">>> Final verification:"
echo "EFS mounts:"
df -h | grep efs
echo "CloudWatch agent status:"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -c default -a query || echo "CloudWatch agent query failed"