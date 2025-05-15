#!/bin/bash
# EC2 User Data script using EFS DNS names for Node.js app deployment

exec > >(tee /var/log/user-data.log | tee /mnt/efs/logs/init.log) 2>&1
echo ">>> Starting EC2 provisioning at $(date)"

# === System Preparation ===
yum update -y
yum install -y git amazon-efs-utils nfs-utils nodejs npm rsync -y
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

# === Setup App Directory Structure ===
mkdir -p /mnt/efs/code/{nodejs-app,git-repo}
touch /mnt/efs/logs/git-updates.log
chmod 644 /mnt/efs/logs/git-updates.log

# === Clone Repository ===
cd /mnt/efs/code/git-repo || exit 1
git clone --single-branch --branch nodejs "${git_repo_url}" .
mv nodejs/* . && rm -rf nodejs

# === Git Hook for Deployment ===
cat > .git/hooks/post-receive <<'HOOK'
#!/bin/bash
echo ">>> Git update received at $(date)" >> /mnt/efs/logs/git-updates.log

rsync -av --exclude='.git' --delete /mnt/efs/code/git-repo/ /mnt/efs/code/nodejs-app/
cd /mnt/efs/code/nodejs-app
npm install

pm2 restart nodejs-app || pm2 start app.js --name nodejs-app

echo ">>> Deployment completed at $(date)" >> /mnt/efs/logs/git-updates.log
HOOK

chmod +x .git/hooks/post-receive

# === Initial Deployment ===
echo ">>> Initial deployment at $(date)" >> /mnt/efs/logs/git-updates.log
rsync -av --exclude='.git' --delete /mnt/efs/code/git-repo/ /mnt/efs/code/nodejs-app/

# === .env Config ===
cat > /mnt/efs/code/nodejs-app/.env <<EOF
PORT=3000
NODE_ENV=production
LOG_PATH=/mnt/efs/logs
DATA_PATH=/mnt/efs/data
EOF

# === Install and Run App ===
cd /mnt/efs/code/nodejs-app
npm install
pm2 start app.js --name nodejs-app
pm2 startup
pm2 save

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
