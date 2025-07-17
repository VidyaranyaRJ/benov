#!/bin/bash

set -e

# === Database environment setup ===
cat <<EOF | sudo tee /etc/profile.d/db_env.sh
export DB_HOST="${DB_HOST}"
export DB_USER="${DB_USER}"
export DB_PASS="${DB_PASS}"
export DB_NAME="${DB_NAME}"
EOF

sudo chmod 644 /etc/profile.d/db_env.sh
echo "✅ Database environment variables configured"

source /etc/profile.d/db_env.sh
echo "✅ Loaded DB env: $DB_HOST / $DB_USER / $DB_NAME"

# === EC2 Metadata ===
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Running on EC2 instance: $INSTANCE_ID"

# === Configuration ===
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/nodejs-app.zip"
EFS_MOUNT="/mnt/efs"
APP_DIR="${EFS_MOUNT}/code"
TEMP_DIR="${APP_DIR}/nodejs-app-temp"
DEPLOY_DIR="${APP_DIR}/nodejs-app"

# === EFS Mount Status Check ===
echo "🔍 Checking EFS mount status..."
df -h -t nfs4 | grep -E "(amazonaws|efs)" || echo "No EFS mounts found"
mount | grep -E "/mnt/efs/(code|logs|org)" || echo "⚠️ EFS mounts not currently listed"

# === Enhanced EFS Mount Detection ===
EFS_CODE_MOUNTED=false
EFS_LOGS_MOUNTED=false
EFS_ORG_MOUNTED=false

check_efs_mount() {
  local mount_point=$1
  local mount_name=$2
  
  echo "🔍 Checking $mount_name mount at $mount_point..."
  
  # Create directory if it doesn't exist
  sudo mkdir -p "$mount_point"
  
  # Check if already mounted
  if mountpoint -q "$mount_point" 2>/dev/null; then
    echo "✅ $mount_name is already mounted"
    return 0
  fi
  
  # Check if we can write to it (EFS test)
  if [ -d "$mount_point" ] && sudo touch "$mount_point/.test" 2>/dev/null; then
    sudo rm -f "$mount_point/.test" 2>/dev/null
    echo "✅ $mount_name directory is accessible"
    return 0
  fi
  
  echo "❌ $mount_name is not accessible"
  return 1
}

# Check each EFS mount
if check_efs_mount "${EFS_MOUNT}/code" "EFS Code"; then
  EFS_CODE_MOUNTED=true
fi

if check_efs_mount "${EFS_MOUNT}/logs" "EFS Logs"; then
  EFS_LOGS_MOUNTED=true
fi

if check_efs_mount "${EFS_MOUNT}/org" "EFS Org"; then
  EFS_ORG_MOUNTED=true
fi

# === Attempt Manual EFS Mount if needed ===
if [ "$EFS_CODE_MOUNTED" = false ] && [ -n "$EFS_CODE_DNS" ]; then
  echo "🔧 Attempting manual EFS mount for code directory..."
  sudo mount -t nfs4 -o _netdev "${EFS_CODE_DNS}:/" "${EFS_MOUNT}/code" || echo "❌ Manual mount failed"
  
  if mountpoint -q "${EFS_MOUNT}/code"; then
    EFS_CODE_MOUNTED=true
    echo "✅ Manual EFS code mount successful"
  fi
fi

if [ "$EFS_LOGS_MOUNTED" = false ] && [ -n "$EFS_LOGS_DNS" ]; then
  echo "🔧 Attempting manual EFS mount for logs directory..."
  sudo mount -t nfs4 -o _netdev "${EFS_LOGS_DNS}:/" "${EFS_MOUNT}/logs" || echo "❌ Manual mount failed"
  
  if mountpoint -q "${EFS_MOUNT}/logs"; then
    EFS_LOGS_MOUNTED=true
    echo "✅ Manual EFS logs mount successful"
  fi
fi

# === Storage Fallback Logic ===
if [ "$EFS_CODE_MOUNTED" = false ]; then
  echo "⚠️ EFS code directory not available, using local storage"
  EFS_MOUNT="/opt/app-storage"
  APP_DIR="${EFS_MOUNT}/code"
  TEMP_DIR="${APP_DIR}/nodejs-app-temp"
  DEPLOY_DIR="${APP_DIR}/nodejs-app"
fi

if [ "$EFS_LOGS_MOUNTED" = false ]; then
  echo "⚠️ EFS logs directory not available, using local storage"
  LOG_DIR="${EFS_MOUNT}/logs"
else
  LOG_DIR="${EFS_MOUNT}/logs"
fi

# === Directory Setup ===
echo "📁 Setting up directories..."
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
HOSTNAME=$(hostname)

# Create directories with proper permissions
sudo mkdir -p "${EFS_MOUNT}" "${APP_DIR}" "${TEMP_DIR}" "${LOG_DIR}"

# Fix permissions
echo "🔧 Setting up permissions..."
sudo chown -R ec2-user:ec2-user "${EFS_MOUNT}"
sudo chmod -R 755 "${EFS_MOUNT}"

# Verify write permissions
for DIR in "${APP_DIR}" "${LOG_DIR}"; do
  if [ ! -w "$DIR" ]; then
    echo "⚠️ $DIR is not writable, fixing permissions..."
    sudo chown -R ec2-user:ec2-user "$DIR"
    sudo chmod -R 755 "$DIR"
  fi
done

# === Logging Setup ===
export NODE_APP_LOG_PATH="${LOG_DIR}/${YEAR}-${MONTH}-${DAY}-${HOSTNAME}-app.log"
echo "📝 Log path set to: ${NODE_APP_LOG_PATH}"

# === Application Download and Setup ===
echo "📥 Downloading application from S3..."
aws s3 cp s3://${S3_BUCKET}/${S3_KEY} ${APP_DIR}/nodejs-app.zip

echo "📦 Extracting application..."
unzip -o ${APP_DIR}/nodejs-app.zip -d ${TEMP_DIR}

# === Find and Install Dependencies ===
echo "🔍 Locating package.json..."
if [ -f "${TEMP_DIR}/package.json" ]; then
  cd ${TEMP_DIR}
  echo "✅ Found package.json in root"
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  cd ${TEMP_DIR}/Nodejs
  echo "✅ Found package.json in Nodejs subdirectory"
else
  echo "❌ package.json not found! Searching..."
  find ${TEMP_DIR} -name "package.json" 2>/dev/null || true
  exit 1
fi

# === Node.js Installation ===
if ! command -v node &>/dev/null; then
  echo "📦 Installing Node.js..."
  curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
  sudo dnf install -y nodejs
fi

# === NPM Dependencies ===
echo "📦 Installing npm dependencies..."
npm install
npm install dotenv compression ws mysql2 @faker-js/faker response-time @aws-sdk/client-cloudwatch-logs

# Verify critical packages
if [ -d "node_modules/@aws-sdk/client-cloudwatch-logs" ]; then
  echo "✅ AWS CloudWatch Logs SDK installed"
else
  echo "❌ AWS CloudWatch Logs SDK missing"
fi

# === PM2 Installation ===
if ! command -v pm2 &>/dev/null; then
  echo "📦 Installing PM2..."
  sudo npm install -g pm2
fi

# === Application Backup and Deployment ===
if [ -d "${DEPLOY_DIR}" ]; then
  echo "🔄 Backing up existing application..."
  rm -rf ${APP_DIR}/nodejs-app-backup || true
  mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
fi

echo "🚀 Deploying application..."
mkdir -p ${DEPLOY_DIR}
if [ -f "${TEMP_DIR}/package.json" ]; then
  mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
fi

# === Environment Configuration ===
cd ${DEPLOY_DIR}
cat > .env << EOF
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
AWS_REGION=${AWS_REGION:-us-east-2}
HOSTNAME=${HOSTNAME}
LOG_FILE=${NODE_APP_LOG_PATH}
EFS_CODE_PATH=${APP_DIR}
EFS_LOGS_PATH=${LOG_DIR}
EFS_CODE_MOUNTED=${EFS_CODE_MOUNTED}
EFS_LOGS_MOUNTED=${EFS_LOGS_MOUNTED}

# Database Configuration
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}
EOF

echo "✅ Environment configuration created"

# === PM2 Application Management ===
export APP_LOG_FILE="${NODE_APP_LOG_PATH}"

# Load environment variables
if [ -f ".env" ]; then
  set -a
  source .env
  set +a
fi

# Start/Restart application
if pm2 describe nodejs-app >/dev/null 2>&1; then
  echo "🔄 Reloading existing nodejs-app..."
  pm2 reload nodejs-app
else
  echo "🆕 Starting new nodejs-app..."
  pm2 start app.js --name nodejs-app --log ${NODE_APP_LOG_PATH}
fi

pm2 save

# === PM2 Startup Configuration ===
echo "🔧 Configuring PM2 auto-start..."
if ! systemctl status pm2-$(whoami) >/dev/null 2>&1; then
  STARTUP_CMD=$(pm2 startup systemd -u $(whoami) --hp /home/$(whoami) | grep 'sudo' | tail -n 1)
  if [ -n "$STARTUP_CMD" ]; then
    echo "Executing: $STARTUP_CMD"
    eval $STARTUP_CMD
    pm2 save
    echo "✅ PM2 auto-start configured"
  fi
else
  echo "✅ PM2 auto-start already configured"
fi

# === Cleanup ===
cd /tmp
rm -rf ${TEMP_DIR}

# === HTTPS Setup ===
echo "🔒 Setting up HTTPS via Nginx..."
sudo yum install -y nginx

# Generate self-signed certificate
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/self.key \
  -out /etc/nginx/ssl/self.crt \
  -subj "/CN=benevolaite.com"

# Configure Nginx reverse proxy
sudo tee /etc/nginx/conf.d/ssl.conf > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name benevolaite.com;

    ssl_certificate     /etc/nginx/ssl/self.crt;
    ssl_certificate_key /etc/nginx/ssl/self.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Start Nginx
sudo nginx -t && sudo systemctl restart nginx && sudo systemctl enable nginx

# === Final Status Report ===
echo ""
echo "✅ Deployment completed successfully!"
echo "📋 Deployment Summary:"
echo "  - Instance ID: $INSTANCE_ID"
echo "  - EFS Code Mounted: $EFS_CODE_MOUNTED"
echo "  - EFS Logs Mounted: $EFS_LOGS_MOUNTED"
echo "  - App Directory: $DEPLOY_DIR"
echo "  - Log Directory: $LOG_DIR"
echo "  - Storage Type: $([ "$EFS_CODE_MOUNTED" = true ] && echo "EFS" || echo "Local")"
echo "  - Log File: $NODE_APP_LOG_PATH"
echo ""
echo "🌐 Application accessible on:"
echo "  - HTTP: http://localhost:3000"
echo "  - HTTPS: https://benevolaite.com:443"
echo ""
echo "🔧 Management commands:"
echo "  - Check logs: pm2 logs nodejs-app"
echo "  - Check status: pm2 status"
echo "  - Restart app: pm2 restart nodejs-app"
echo "  - EFS status: df -h -t nfs4"

# Show final PM2 status
pm2 list