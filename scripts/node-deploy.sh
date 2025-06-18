#!/bin/bash
# set -e

# # Fetch EC2 instance ID via IMDSv2
# TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
#   -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

# INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
#   -s http://169.254.169.254/latest/meta-data/instance-id)

# echo "Running on EC2 instance: $INSTANCE_ID"

# # Configuration
# S3_BUCKET="vj-test-benvolate"
# S3_KEY="nodejs/nodejs-app.zip"
# EFS_MOUNT="/mnt/efs"
# APP_DIR="${EFS_MOUNT}/code"
# TEMP_DIR="${APP_DIR}/nodejs-app-temp"
# DEPLOY_DIR="${APP_DIR}/nodejs-app"

# echo "Starting deployment process..."

# # Create necessary directories
# mkdir -p ${APP_DIR}
# mkdir -p ${TEMP_DIR}

# # Download the latest application from S3
# echo "Downloading application from S3..."
# aws s3 cp s3://${S3_BUCKET}/${S3_KEY} ${APP_DIR}/nodejs-app.zip

# # Extract the application
# echo "Extracting application..."
# unzip -o ${APP_DIR}/nodejs-app.zip -d ${TEMP_DIR}

# # Determine app root and install dependencies
# if [ -f "${TEMP_DIR}/package.json" ]; then
#   echo "Found package.json at root level"
#   cd ${TEMP_DIR}
# elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
#   echo "Found package.json in Nodejs subdirectory"
#   cd ${TEMP_DIR}/Nodejs
# else
#   echo "ERROR: Could not find package.json!"
#   find ${TEMP_DIR} -type f -name "package.json"
#   exit 1
# fi

# # Install app dependencies
# echo "Installing dependencies..."
# npm install
# npm install dotenv

# # Install PM2 early to avoid ENOENT errors later
# if ! command -v pm2 &> /dev/null; then
#   echo "Installing PM2..."
#   npm install -g pm2
# fi

# # Setup log directory
# YEAR=$(date +%Y)
# MONTH=$(date +%m)
# DAY=$(date +%d)
# HOSTNAME=$(hostname)
# LOG_DIR="${EFS_MOUNT}/logs/${MONTH}-${DAY}-${YEAR}/${HOSTNAME}"
# mkdir -p "${LOG_DIR}"
# export NODE_APP_LOG_PATH="${LOG_DIR}/node-app.log"
# echo "Log path set to ${NODE_APP_LOG_PATH}"

# # Prepare for deployment
# echo "Preparing for deployment..."
# if [ -d "${DEPLOY_DIR}" ]; then
#   if [ -d "${APP_DIR}/nodejs-app-backup" ]; then
#     rm -rf ${APP_DIR}/nodejs-app-backup
#   fi
#   mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
# fi

# # Move new version to deployment directory
# echo "Moving new version to deploy directory..."
# mkdir -p ${DEPLOY_DIR}
# if [ -f "${TEMP_DIR}/package.json" ]; then
#   mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
# elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
#   mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
# fi

# # Safety: Ensure you're not inside TEMP_DIR before deleting
# if [[ "$PWD" == "$TEMP_DIR"* ]]; then
#   echo "Leaving temp dir before deletion..."
#   cd /tmp
# fi

# # Clean up
# rm -rf ${TEMP_DIR}

# # Start or restart the application with PM2
# cd ${DEPLOY_DIR}
# if pm2 list | grep -q "nodejs-app"; then
#   echo "Restarting application with PM2..."
#   pm2 restart nodejs-app
# else
#   echo "Starting application with PM2..."
#   pm2 start index.js --name nodejs-app
# fi

# echo "✅ Deployment complete!"





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

# === Logging Setup ===
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
HOSTNAME=$(hostname)
LOG_DIR="${EFS_MOUNT}/logs/${MONTH}-${DAY}-${YEAR}/${HOSTNAME}"
mkdir -p "${LOG_DIR}"
export NODE_APP_LOG_PATH="${LOG_DIR}/node-app.log"
echo "Log path set to ${NODE_APP_LOG_PATH}"

# === Prepare ===
echo "Creating directories..."
mkdir -p ${APP_DIR} ${TEMP_DIR}

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
  find ${TEMP_DIR} -name "package.json"
  exit 1
fi

npm install
npm install dotenv

# === Ensure PM2 is Installed ===
if ! command -v pm2 &>/dev/null; then
  npm install -g pm2
fi

# === Backup Old App if Exists ===
if [ -d "${DEPLOY_DIR}" ]; then
  rm -rf ${APP_DIR}/nodejs-app-backup || true
  mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
fi

# === Move App to Deploy Directory ===
mkdir -p ${DEPLOY_DIR}
if [ -f "${TEMP_DIR}/package.json" ]; then
  mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
fi

# === Clean Up ===
cd /tmp
rm -rf ${TEMP_DIR}

# === Start or Restart Node App with PM2 ===
cd ${DEPLOY_DIR}

# Export log path for app to use
export APP_LOG_FILE="${NODE_APP_LOG_PATH}"
echo "Using log: ${APP_LOG_FILE}"

# Use .env if available
if [ -f ".env" ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

if pm2 list | grep -q "nodejs-app"; then
  echo "Restarting nodejs-app with PM2..."
  pm2 restart nodejs-app
else
  echo "Starting nodejs-app with PM2..."
  pm2 start index.js --name nodejs-app --log ${NODE_APP_LOG_PATH}
fi

echo "✅ Node.js application deployed successfully!"
