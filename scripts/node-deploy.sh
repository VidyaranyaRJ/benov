#!/bin/bash

# set -e

# # === Fetch EC2 Instance Metadata ===
# TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
#   -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
# INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
#   -s http://169.254.169.254/latest/meta-data/instance-id)
# echo "Running on EC2 instance: $INSTANCE_ID"

# # === Config ===
# S3_BUCKET="vj-test-benvolate"
# S3_KEY="nodejs/nodejs-app.zip"
# EFS_MOUNT="/mnt/efs"
# APP_DIR="${EFS_MOUNT}/code"
# TEMP_DIR="${APP_DIR}/nodejs-app-temp"
# DEPLOY_DIR="${APP_DIR}/nodejs-app"

# # === Check if EFS is actually mounted, otherwise use local storage ===
# if ! mountpoint -q ${EFS_MOUNT} 2>/dev/null; then
#     echo "⚠️  EFS not mounted at ${EFS_MOUNT}, using local storage instead"
#     EFS_MOUNT="/opt/app-storage"
#     APP_DIR="${EFS_MOUNT}/code"
#     TEMP_DIR="${APP_DIR}/nodejs-app-temp"
#     DEPLOY_DIR="${APP_DIR}/nodejs-app"
# fi

# # === Logging Setup ===
# YEAR=$(date +%Y)
# MONTH=$(date +%m)
# DAY=$(date +%d)
# HOSTNAME=$(hostname)
# LOG_DIR="${EFS_MOUNT}/logs/${MONTH}-${DAY}-${YEAR}/${HOSTNAME}"

# # Create directories with proper permissions
# echo "Creating directories..."
# sudo mkdir -p "${EFS_MOUNT}" "${APP_DIR}" "${TEMP_DIR}" "${LOG_DIR}"
# sudo chown -R $(whoami):$(whoami) "${EFS_MOUNT}"

# export NODE_APP_LOG_PATH="${LOG_DIR}/node-app.log"
# echo "Log path set to ${NODE_APP_LOG_PATH}"

# echo "Downloading from S3..."
# aws s3 cp s3://${S3_BUCKET}/${S3_KEY} ${APP_DIR}/nodejs-app.zip

# echo "Extracting application..."
# unzip -o ${APP_DIR}/nodejs-app.zip -d ${TEMP_DIR}

# # === Locate and Install Dependencies ===
# if [ -f "${TEMP_DIR}/package.json" ]; then
#   cd ${TEMP_DIR}
# elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
#   cd ${TEMP_DIR}/Nodejs
# else
#   echo "ERROR: package.json not found!"
#   find ${TEMP_DIR} -name "package.json" 2>/dev/null || true
#   exit 1
# fi

# # Install Node.js if not present
# if ! command -v node &>/dev/null; then
#     echo "Installing Node.js..."
#     curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
#     sudo dnf install -y nodejs
# fi

# echo "Installing dependencies..."
# npm install
# npm install dotenv

# # === Ensure PM2 is Installed ===
# if ! command -v pm2 &>/dev/null; then
#   echo "Installing PM2..."
#   sudo npm install -g pm2
# fi

# # === Backup Old App if Exists ===
# if [ -d "${DEPLOY_DIR}" ]; then
#   echo "Backing up existing application..."
#   rm -rf ${APP_DIR}/nodejs-app-backup || true
#   mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
# fi

# # === Move App to Deploy Directory ===
# echo "Deploying application..."
# mkdir -p ${DEPLOY_DIR}
# if [ -f "${TEMP_DIR}/package.json" ]; then
#   mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
# elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
#   mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
# fi

# # === Clean Up ===
# cd /tmp
# rm -rf ${TEMP_DIR}

# # === Start or Restart Node App with PM2 ===
# cd ${DEPLOY_DIR}

# # Export log path for app to use
# export APP_LOG_FILE="${NODE_APP_LOG_PATH}"
# echo "Using log: ${APP_LOG_FILE}"

# # Use .env if available
# if [ -f ".env" ]; then
#   echo "Loading environment variables from .env file..."
#   set -a  # automatically export all variables
#   source .env
#   set +a  # stop automatically exporting
# fi

# # Check if app is already running and restart/start accordingly
# if pm2 list | grep -q "nodejs-app"; then
#   echo "Restarting nodejs-app with PM2..."
#   pm2 restart nodejs-app
#   pm2 save
# else
#   echo "Starting nodejs-app with PM2..."
#   pm2 start index.js --name nodejs-app --log ${NODE_APP_LOG_PATH}
#   pm2 save
#   pm2 startup
# fi

# # Show PM2 status
# echo "PM2 Process Status:"
# pm2 list

# echo "✅ Node.js application deployed successfully!"
# echo "🌐 Application should be accessible on port 3000"
# echo "📋 Check logs with: pm2 logs nodejs-app"








set -e

# === Fetch EC2 Instance Metadata ===
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Running on EC2 instance: $INSTANCE_ID"

# === Config ===
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/nodejs-app.zip"
EFS_MOUNT="/mnt/efs"
APP_DIR="${EFS_MOUNT}/code"
TEMP_DIR="${APP_DIR}/nodejs-app-temp"
DEPLOY_DIR="${APP_DIR}/nodejs-app"

# === Check EFS mount status ===
echo "🔍 Checking EFS mount status..."
echo "=== Current mounts ==="
df -h -t nfs4 | grep -E "(amazonaws|efs)" || echo "No EFS mounts found"
echo "=== EFS directories ==="
ls -la /mnt/efs/ 2>/dev/null || echo "/mnt/efs not found"

# === FIX: Better EFS mount detection ===
EFS_CODE_MOUNTED=false
EFS_LOGS_MOUNTED=false

# Check if EFS code directory is mounted and accessible
if mountpoint -q "${EFS_MOUNT}/code" 2>/dev/null || [ -d "${EFS_MOUNT}/code" ] && touch "${EFS_MOUNT}/code/.test" 2>/dev/null; then
    EFS_CODE_MOUNTED=true
    rm -f "${EFS_MOUNT}/code/.test" 2>/dev/null
    echo "✅ EFS code directory is accessible"
else
    echo "⚠️  EFS code directory not accessible"
fi

# Check if EFS logs directory is mounted and accessible
if mountpoint -q "${EFS_MOUNT}/logs" 2>/dev/null || [ -d "${EFS_MOUNT}/logs" ] && touch "${EFS_MOUNT}/logs/.test" 2>/dev/null; then
    EFS_LOGS_MOUNTED=true
    rm -f "${EFS_MOUNT}/logs/.test" 2>/dev/null
    echo "✅ EFS logs directory is accessible"
else
    echo "⚠️  EFS logs directory not accessible"
fi

# === Use local storage if EFS is not available ===
if [ "$EFS_CODE_MOUNTED" = false ]; then
    echo "⚠️  EFS not properly mounted, using local storage instead"
    EFS_MOUNT="/opt/app-storage"
    APP_DIR="${EFS_MOUNT}/code"
    TEMP_DIR="${APP_DIR}/nodejs-app-temp"
    DEPLOY_DIR="${APP_DIR}/nodejs-app"
fi

# === Logging Setup ===
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
HOSTNAME=$(hostname)

if [ "$EFS_LOGS_MOUNTED" = true ]; then
    LOG_DIR="${EFS_MOUNT}/logs/${MONTH}-${DAY}-${YEAR}/${HOSTNAME}"
else
    LOG_DIR="${EFS_MOUNT}/logs/${MONTH}-${DAY}-${YEAR}/${HOSTNAME}"
fi

# Create directories with proper permissions
echo "Creating directories..."
sudo mkdir -p "${EFS_MOUNT}" "${APP_DIR}" "${TEMP_DIR}" "${LOG_DIR}"
sudo chown -R $(whoami):$(whoami) "${EFS_MOUNT}"

export NODE_APP_LOG_PATH="${LOG_DIR}/node-app.log"
echo "Log path set to ${NODE_APP_LOG_PATH}"

echo "Downloading from S3..."
aws s3 cp s3://${S3_BUCKET}/${S3_KEY} ${APP_DIR}/nodejs-app.zip

echo "Extracting application..."
unzip -o ${APP_DIR}/nodejs-app.zip -d ${TEMP_DIR}

# === Locate and Install Dependencies ===
if [ -f "${TEMP_DIR}/package.json" ]; then
  cd ${TEMP_DIR}
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  cd ${TEMP_DIR}/Nodejs
else
  echo "ERROR: package.json not found!"
  find ${TEMP_DIR} -name "package.json" 2>/dev/null || true
  exit 1
fi

# Install Node.js if not present
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo dnf install -y nodejs
fi

echo "Installing dependencies..."
npm install
npm install dotenv

# === Ensure PM2 is Installed ===
if ! command -v pm2 &>/dev/null; then
  echo "Installing PM2..."
  sudo npm install -g pm2
fi

# === Backup Old App if Exists ===
if [ -d "${DEPLOY_DIR}" ]; then
  echo "Backing up existing application..."
  rm -rf ${APP_DIR}/nodejs-app-backup || true
  mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
fi

# === Move App to Deploy Directory ===
echo "Deploying application..."
mkdir -p ${DEPLOY_DIR}
if [ -f "${TEMP_DIR}/package.json" ]; then
  mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
fi

# === Clean Up ===
cd /tmp
rm -rf ${TEMP_DIR}

# === Create .env file with EFS paths ===
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
EFS_MOUNTED=${EFS_CODE_MOUNTED}
EOF

echo "Created .env file with EFS configuration"

# === Start or Restart Node App with PM2 ===
# Export log path for app to use
export APP_LOG_FILE="${NODE_APP_LOG_PATH}"
echo "Using log: ${APP_LOG_FILE}"

# Use .env if available
if [ -f ".env" ]; then
  echo "Loading environment variables from .env file..."
  set -a  # automatically export all variables
  source .env
  set +a  # stop automatically exporting
fi

# Check if app is already running and restart/start accordingly
if pm2 list | grep -q "nodejs-app"; then
  echo "Restarting nodejs-app with PM2..."
  pm2 restart nodejs-app
  pm2 save
else
  echo "Starting nodejs-app with PM2..."
  pm2 start index.js --name nodejs-app --log ${NODE_APP_LOG_PATH}
  pm2 save
  pm2 startup
fi

# Show PM2 status
echo "PM2 Process Status:"
pm2 list

# === Final Status Report ===
echo ""
echo "✅ Node.js application deployed successfully!"
echo "📋 Deployment Summary:"
echo "  - EFS Code Mounted: $EFS_CODE_MOUNTED"
echo "  - EFS Logs Mounted: $EFS_LOGS_MOUNTED"
echo "  - App Directory: $DEPLOY_DIR"
echo "  - Log Directory: $LOG_DIR"
echo "  - Storage Type: $([ "$EFS_CODE_MOUNTED" = true ] && echo "EFS" || echo "Local")"
echo ""
echo "🌐 Application should be accessible on port 3000"
echo "📋 Check logs with: pm2 logs nodejs-app"
echo "🔍 EFS Status: df -h -t nfs4"