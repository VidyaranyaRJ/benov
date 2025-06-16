#!/bin/bash
set -e

# Fetch EC2 instance ID via IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)

echo "Running on EC2 instance: $INSTANCE_ID"


# Configuration
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/nodejs-app.zip"
EFS_MOUNT="/mnt/efs"
APP_DIR="${EFS_MOUNT}/code"
TEMP_DIR="${APP_DIR}/nodejs-app-temp"
DEPLOY_DIR="${APP_DIR}/nodejs-app"

echo "Starting deployment process..."

# Create necessary directories
mkdir -p ${APP_DIR}
mkdir -p ${TEMP_DIR}

# Download the latest application from S3
echo "Downloading application from S3..."
aws s3 cp s3://${S3_BUCKET}/${S3_KEY} ${APP_DIR}/nodejs-app.zip

# Extract the application
echo "Extracting application..."
unzip -o ${APP_DIR}/nodejs-app.zip -d ${TEMP_DIR}

# Check where package.json is located
if [ -f "${TEMP_DIR}/package.json" ]; then
  echo "Found package.json at root level"
  cd ${TEMP_DIR}
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  echo "Found package.json in Nodejs subdirectory"
  cd ${TEMP_DIR}/Nodejs
else
  echo "ERROR: Could not find package.json!"
  find ${TEMP_DIR} -type f -name "package.json"
  exit 1
fi

# Install dependencies
echo "Installing dependencies..."
npm install 

npm install dotenv

# Prepare for deployment
echo "Preparing for deployment..."
if [ -d "${DEPLOY_DIR}" ]; then
  # Create backup of current deployment
  if [ -d "${APP_DIR}/nodejs-app-backup" ]; then
    rm -rf ${APP_DIR}/nodejs-app-backup
  fi
  mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
fi

# Move the new version to the deployment directory
echo "Moving new version to deploy directory..."
if [ -f "${TEMP_DIR}/package.json" ]; then
  # We're already in the temp dir
  mkdir -p ${DEPLOY_DIR}
  mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  # We need to move from the Nodejs subdirectory
  mkdir -p ${DEPLOY_DIR}
  mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
fi

# Clean up temp directory
rm -rf ${TEMP_DIR}

# Check if PM2 is installed, if not, install it
if ! command -v pm2 &> /dev/null; then
  echo "Installing PM2..."
  npm install -g pm2
fi

# Start or restart the application with PM2
cd ${DEPLOY_DIR}
if pm2 list | grep -q "nodejs-app"; then
  echo "Restarting application with PM2..."
  pm2 restart nodejs-app
else
  echo "Starting application with PM2..."
  pm2 start index.js --name nodejs-app
fi

echo "Deployment complete!"
