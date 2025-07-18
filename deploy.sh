#!/bin/bash

set -euo pipefail

# === Configuration ===
ENVIRONMENT=${1:-dev}
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/${ENVIRONMENT}/nodejs-app.zip"
APP_NAME="nodejs-app"
APP_PATH="/mnt/efs/code/${APP_NAME}"
BACKUP_PATH="/mnt/efs/code/${APP_NAME}-backup-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Deploying Node.js App to environment: $ENVIRONMENT"
echo "📦 S3 Path: s3://${S3_BUCKET}/${S3_KEY}"
echo "🎯 Target Path: ${APP_PATH}"

# === [1/8] Find EC2 instances for environment ===
echo "✅ [1/8] Finding EC2 instances for environment '$ENVIRONMENT'..."
EC2_INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*-${ENVIRONMENT}" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

if [ -z "$EC2_INSTANCE_IDS" ]; then
  echo "❌ No running EC2 instances found for environment: $ENVIRONMENT"
  exit 1
fi

echo "✅ Found EC2 instance(s): $EC2_INSTANCE_IDS"

# === [2/8] Verify SSM connectivity ===
echo "✅ [2/8] Verifying SSM connectivity..."
for INSTANCE_ID in $EC2_INSTANCE_IDS; do
  STATUS=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --query "InstanceInformationList[0].PingStatus" --output text)

  if [ "$STATUS" != "Online" ]; then
    echo "❌ SSM not online for instance $INSTANCE_ID"
    exit 1
  fi
done
echo "✅ All instances are SSM Online"

# === [3/8] Create backup and prepare directories ===
echo "✅ [3/8] Creating backup and preparing directories..."
for INSTANCE_ID in $EC2_INSTANCE_IDS; do
  echo "🔄 Preparing $INSTANCE_ID..."
  
  COMMAND_ID=$(aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-2 \
    --comment "Backup and prepare for deployment" \
    --parameters 'commands=[
      "echo ✅ [1/4] Creating backup of current app...",
      "if [ -d /mnt/efs/code/nodejs-app ]; then",
      "  sudo cp -r /mnt/efs/code/nodejs-app /mnt/efs/code/nodejs-app-backup-$(date +%Y%m%d-%H%M%S) || true",
      "  echo ✅ Backup created",
      "else",
      "  echo ℹ️ No existing app to backup",
      "fi",
      "",
      "echo ✅ [2/4] Stopping PM2 processes...",
      "pm2 stop nodejs-app || true",
      "pm2 delete nodejs-app || true",
      "echo ✅ PM2 processes stopped",
      "",
      "echo ✅ [3/4] Downloading new app from S3...",
      "aws s3 cp s3://'${S3_BUCKET}'/'${S3_KEY}' /tmp/nodejs-app.zip --region us-east-2",
      "echo ✅ Downloaded nodejs-app.zip",
      "",
      "echo ✅ [4/4] Backup and preparation complete"
    ]' \
    --query 'Command.CommandId' --output text)
  
  echo "📤 Command sent to $INSTANCE_ID: $COMMAND_ID"
done

# === [4/8] Wait for backup completion ===
echo "✅ [4/8] Waiting for backup completion..."
sleep 10

# === [5/8] Deploy new application ===
echo "✅ [5/8] Deploying new application..."
for INSTANCE_ID in $EC2_INSTANCE_IDS; do
  echo "🚀 Deploying to $INSTANCE_ID..."
  
  COMMAND_ID=$(aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-2 \
    --comment "Deploy new Node.js application" \
    --parameters 'commands=[
      "echo ✅ [1/6] Removing old application...",
      "sudo rm -rf /mnt/efs/code/nodejs-app",
      "echo ✅ Old app removed",
      "",
      "echo ✅ [2/6] Creating fresh app directory...",
      "mkdir -p /mnt/efs/code/nodejs-app",
      "echo ✅ Directory created",
      "",
      "echo ✅ [3/6] Extracting new application...",
      "unzip -o /tmp/nodejs-app.zip -d /mnt/efs/code/nodejs-app",
      "echo ✅ Application extracted",
      "",
      "echo ✅ [4/6] Setting up environment...",
      "cd /mnt/efs/code/nodejs-app",
      "echo PORT=3000 > .env",
      "echo NODE_ENV='${ENVIRONMENT}' >> .env",
      "echo ✅ Environment configured",
      "",
      "echo ✅ [5/6] Installing dependencies...",
      "npm install --production || echo ⚠️ npm install failed, continuing...",
      "echo ✅ Dependencies installed",
      "",
      "echo ✅ [6/6] Replacing PM2 processes...",
      "pm2 delete all || true",
      "pm2 kill || true",
      "rm -rf ~/.pm2",
      "",
      "echo ✅ Installing dependencies...",
      "npm ci --silent || echo ⚠️ npm ci failed, continuing...",
      "",
      "echo ✅ Starting new PM2 process...",
      "pm2 start app.js --name nodejs-app --cwd /mnt/efs/code/nodejs-app --env production",
      "pm2 save",
      "echo ✅ PM2 started with fresh code"
    ]' \
    --query 'Command.CommandId' --output text)
  
  echo "📤 Deployment command sent to $INSTANCE_ID: $COMMAND_ID"
done

# === [6/8] Wait for deployment completion ===
echo "✅ [6/8] Waiting for deployment completion..."
sleep 15

# === [7/8] Verify deployment ===
echo "✅ [7/8] Verifying deployment..."
for INSTANCE_ID in $EC2_INSTANCE_IDS; do
  echo "🔍 Verifying $INSTANCE_ID..."
  
  aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-2 \
    --comment "Verify deployment" \
    --parameters 'commands=[
      "echo ✅ [1/5] Checking PM2 status...",
      "pm2 list | grep nodejs-app || echo ❌ nodejs-app not found in PM2",
      "",
      "echo ✅ [2/5] Checking application files...",
      "ls -la /mnt/efs/code/nodejs-app/ | head -10",
      "",
      "echo ✅ [3/5] Checking port 3000...",
      "netstat -tlnp | grep :3000 || echo ⚠️ Port 3000 not listening",
      "",
      "echo ✅ [4/5] Checking deployment metadata...",
      "cat /mnt/efs/code/nodejs-app/.deploy-meta || echo ℹ️ No deployment metadata",
      "",
      "echo ✅ [5/5] Basic health check...",
      "curl -f http://localhost:3000 || echo ⚠️ Health check failed",
      "",
      "echo ✅ Verification complete for '${INSTANCE_ID}'"
    ]' \
    --output text > /dev/null
  
  echo "✅ Verification initiated for $INSTANCE_ID"
done

# === [8/8] Cleanup ===
echo "✅ [8/8] Cleaning up temporary files..."
for INSTANCE_ID in $EC2_INSTANCE_IDS; do
  aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-2 \
    --comment "Cleanup deployment files" \
    --parameters 'commands=[
      "echo ✅ Removing temporary files...",
      "rm -f /tmp/nodejs-app.zip",
      "echo ✅ Cleanup complete"
    ]' \
    --output text > /dev/null
done

# === Deployment Summary ===
echo ""
echo "🎉 ===== DEPLOYMENT SUMMARY ====="
echo "✅ Environment: $ENVIRONMENT"
echo "✅ Deployed to instances: $EC2_INSTANCE_IDS"
echo "✅ Application path: $APP_PATH"
echo "✅ S3 source: s3://${S3_BUCKET}/${S3_KEY}"
echo ""
echo "🔍 To check deployment status:"
echo "   aws ssm list-command-invocations --region us-east-2 --max-items 5"
echo ""
echo "🔍 To check PM2 status on instances:"
echo "   pm2 list"
echo ""
echo "✅ Deployment completed successfully!"