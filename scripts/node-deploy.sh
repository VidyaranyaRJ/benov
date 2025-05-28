#!/bin/bash
# set -e

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

# # Check where package.json is located
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

# # Install dependencies
# echo "Installing dependencies..."
# npm install --production

# # Prepare for deployment
# echo "Preparing for deployment..."
# if [ -d "${DEPLOY_DIR}" ]; then
#   # Create backup of current deployment
#   if [ -d "${APP_DIR}/nodejs-app-backup" ]; then
#     rm -rf ${APP_DIR}/nodejs-app-backup
#   fi
#   mv ${DEPLOY_DIR} ${APP_DIR}/nodejs-app-backup
# fi

# # Move the new version to the deployment directory
# echo "Moving new version to deploy directory..."
# if [ -f "${TEMP_DIR}/package.json" ]; then
#   # We're already in the temp dir
#   mkdir -p ${DEPLOY_DIR}
#   mv ${TEMP_DIR}/* ${DEPLOY_DIR}/
# elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
#   # We need to move from the Nodejs subdirectory
#   mkdir -p ${DEPLOY_DIR}
#   mv ${TEMP_DIR}/Nodejs/* ${DEPLOY_DIR}/
# fi

# # Clean up temp directory
# rm -rf ${TEMP_DIR}

# # Check if PM2 is installed, if not, install it
# if ! command -v pm2 &> /dev/null; then
#   echo "Installing PM2..."
#   npm install -g pm2
# fi

# # Start or restart the application with PM2
# cd ${DEPLOY_DIR}
# if pm2 list | grep -q "nodejs-app"; then
#   echo "Restarting application with PM2..."
#   pm2 restart nodejs-app
# else
#   echo "Starting application with PM2..."
#   pm2 start index.js --name nodejs-app
# fi

# echo "Deployment complete!"




set -e

# Configuration
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/nodejs-app.zip"
EFS_MOUNT="/mnt/efs"
APP_DIR="${EFS_MOUNT}/code"
TEMP_DIR="${APP_DIR}/nodejs-app-temp"
DEPLOY_DIR="${APP_DIR}/nodejs-app"
LOG_DIR="${EFS_MOUNT}/logs"

echo "🚀 Starting deployment process..."

# Create necessary directories
mkdir -p "$APP_DIR" "$TEMP_DIR" "$LOG_DIR"

# Fix EFS log directory ownership
echo "🔐 Fixing log directory permissions"
sudo chown -R ec2-user:ec2-user "$LOG_DIR"
chmod 755 "$LOG_DIR"

# Download the latest application from S3
echo "☁️ Downloading application from S3..."
aws s3 cp "s3://${S3_BUCKET}/${S3_KEY}" "${APP_DIR}/nodejs-app.zip"

# Extract the application
echo "📦 Extracting application..."
unzip -o "${APP_DIR}/nodejs-app.zip" -d "$TEMP_DIR"

# Determine source folder
if [ -f "${TEMP_DIR}/package.json" ]; then
  echo "📁 Found package.json at root level"
  cd "$TEMP_DIR"
elif [ -f "${TEMP_DIR}/Nodejs/package.json" ]; then
  echo "📁 Found package.json in Nodejs subdirectory"
  cd "${TEMP_DIR}/Nodejs"
else
  echo "❌ ERROR: Could not find package.json!"
  find "$TEMP_DIR" -type f -name "package.json"
  exit 1
fi

# Install dependencies
echo "📦 Installing production dependencies..."
npm install --production

# Backup old deployment
if [ -d "$DEPLOY_DIR" ]; then
  echo "🗃️ Backing up previous deployment..."
  rm -rf "${APP_DIR}/nodejs-app-backup"
  mv "$DEPLOY_DIR" "${APP_DIR}/nodejs-app-backup"
fi

# Move new version into deploy dir
echo "🚚 Moving new version to deployment directory..."
mkdir -p "$DEPLOY_DIR"
mv * "$DEPLOY_DIR"

# Clean up temp dir
rm -rf "$TEMP_DIR"

# Ensure PM2 is installed
if ! command -v pm2 &> /dev/null; then
  echo "🔧 Installing PM2 globally..."
  npm install -g pm2
fi

# Start or restart app with PM2 and redirect logs to EFS
cd "$DEPLOY_DIR"
echo "🚀 Launching Node.js app with PM2 (logs to EFS)..."

pm2 delete nodejs-app || true
pm2 start index.js \
  --name nodejs-app \
  --output "$LOG_DIR/out.log" \
  --error "$LOG_DIR/error.log" \
  --log "$LOG_DIR/app.log"

pm2 save
pm2 startup

# Restart CloudWatch Agent to pick up logs
echo "📡 Restarting CloudWatch Agent..."
sudo systemctl restart amazon-cloudwatch-agent

echo "✅ Deployment complete. App is running. Logs are redirected to $LOG_DIR and being shipped to CloudWatch."
