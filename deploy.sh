#!/bin/bash


# set -euo pipefail

# # === Config ===
# ENVIRONMENT=${1:-dev}
# S3_BUCKET="vj-test-benvolate"
# S3_KEY="nodejs/${ENVIRONMENT}/nodejs-app.zip"
# ZIP_FILE="/tmp/nodejs-app.zip"

# echo "🚀 Deploying Nodejs to environment: $ENVIRONMENT"
# echo "🔧 S3 Path: s3://${S3_BUCKET}/${S3_KEY}"

# # === [1/7] Zip Nodejs/ directory ===
# echo "✅ [1/7] Zipping Nodejs/ folder..."
# cd Nodejs/
# zip -r -q "$ZIP_FILE" ./*
# cd - > /dev/null

# # === [2/7] Upload to S3 ===
# echo "✅ [2/7] Uploading ZIP to S3..."
# aws s3 cp "$ZIP_FILE" "s3://${S3_BUCKET}/${S3_KEY}" --region us-east-2

# # === [3/7] Find EC2s for environment ===
# echo "✅ [3/7] Finding EC2 instances for environment '$ENVIRONMENT'..."
# EC2_INSTANCE_IDS=$(aws ec2 describe-instances \
#   --filters "Name=tag:Name,Values=*-${ENVIRONMENT}" "Name=instance-state-name,Values=running" \
#   --query "Reservations[].Instances[].InstanceId" --output text)

# if [ -z "$EC2_INSTANCE_IDS" ]; then
#   echo "❌ No running EC2 instances found for environment: $ENVIRONMENT"
#   exit 1
# else
#   echo "✅ Found EC2 instance(s): $EC2_INSTANCE_IDS"
# fi

# # === [4/7] Verify SSM Online ===
# echo "✅ [4/7] Checking SSM connectivity..."
# for INSTANCE_ID in $EC2_INSTANCE_IDS; do
#   STATUS=$(aws ssm describe-instance-information \
#     --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
#     --query "InstanceInformationList[0].PingStatus" --output text)

#   if [ "$STATUS" != "Online" ]; then
#     echo "❌ SSM not online for instance $INSTANCE_ID"
#     exit 1
#   fi
# done
# echo "✅ All instances have SSM Online"

# # === [5/7] Run node-deploy.sh via SSM ===
# echo "✅ [5/7] Triggering deployment via SSM..."

# for INSTANCE_ID in $EC2_INSTANCE_IDS; do
#   echo "🚀 Deploying to $INSTANCE_ID..."

#   aws ssm send-command \
#     --document-name "AWS-RunShellScript" \
#     --instance-ids "$INSTANCE_ID" \
#     --region us-east-2 \
#     --comment "Deploy Node.js App via SSM" \
#     --parameters 'commands=[
#       "echo ✅ [1/6] Downloading app ZIP from S3...",
#       "aws s3 cp s3://'${S3_BUCKET}'/'${S3_KEY}' /tmp/nodejs-app.zip --region us-east-2",

#       "echo ✅ [2/6] Extracting to /mnt/efs/code/nodejs-app...",
#       "sudo rm -rf /mnt/efs/code/nodejs-app",
#       "mkdir -p /mnt/efs/code/nodejs-app",
#       "unzip -o /tmp/nodejs-app.zip -d /mnt/efs/code/nodejs-app",

#       "echo ✅ [3/6] Running node-deploy.sh...",
#       "chmod +x /mnt/efs/code/nodejs-app/node-deploy.sh",
#       "bash /mnt/efs/code/nodejs-app/node-deploy.sh",

#       "echo ✅ [4/6] Checking PM2...",
#       "pm2 list | grep nodejs-app || echo ⚠️ nodejs-app not running",

#       "echo ✅ [5/6] Checking port 3000...",
#       "lsof -i:3000 || echo ✅ Port 3000 free",

#       "echo ✅ [6/6] Finished deployment on '${INSTANCE_ID}'"
#     ]' \
#     --output text
# done

# # === [6/7] Done ===
# echo "✅ [6/7] Deploy triggered on all instances"
# echo "✅ [7/7] Done!"



#!/bin/bash

set -euo pipefail

# === Config ===
ENVIRONMENT=${1:-dev}
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/${ENVIRONMENT}/nodejs-app.zip"
ZIP_FILE="/tmp/nodejs-app.zip"

echo "🚀 Deploying Node.js to environment: $ENVIRONMENT"
echo "📦 S3 Path: s3://${S3_BUCKET}/${S3_KEY}"

# === [1/7] Zip Nodejs/ directory ===
echo "✅ [1/7] Zipping Nodejs/ folder..."
cd Nodejs/
zip -r -q "$ZIP_FILE" ./*
cd - > /dev/null

# === [2/7] Upload to S3 ===
echo "✅ [2/7] Uploading ZIP to S3..."
aws s3 cp "$ZIP_FILE" "s3://${S3_BUCKET}/${S3_KEY}" --region us-east-2

# === [3/7] Find EC2s for environment ===
echo "✅ [3/7] Finding EC2 instances for environment '$ENVIRONMENT'..."
EC2_INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*-${ENVIRONMENT}" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

if [ -z "$EC2_INSTANCE_IDS" ]; then
  echo "❌ No running EC2 instances found for environment: $ENVIRONMENT"
  exit 1
fi
echo "✅ Found EC2 instance(s): $EC2_INSTANCE_IDS"

# === [4/7] Verify SSM Online ===
echo "✅ [4/7] Verifying SSM connectivity..."
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

# === [5/7] Run deployment script on EC2s ===
echo "✅ [5/7] Triggering deployment via SSM..."

for INSTANCE_ID in $EC2_INSTANCE_IDS; do
  echo "🚀 Deploying to $INSTANCE_ID..."
  aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-2 \
    --comment "Deploy Node.js App" \
    --parameters 'commands=[
      "echo ✅ [1/6] Downloading app ZIP from S3...",
      "aws s3 cp s3://'${S3_BUCKET}'/'${S3_KEY}' /tmp/nodejs-app.zip --region us-east-2",

      "echo ✅ [2/6] Replacing app contents at /mnt/efs/code/nodejs-app...",
      "sudo rm -rf /mnt/efs/code/nodejs-app",
      "mkdir -p /mnt/efs/code/nodejs-app",
      "unzip -o /tmp/nodejs-app.zip -d /mnt/efs/code/nodejs-app",

      "echo ✅ [3/6] Rebuilding PM2 app...",
      "cd /mnt/efs/code/nodejs-app",
      "echo PORT=3000 > .env",
      "pm2 delete nodejs-app || true",
      "pm2 start app.js --name nodejs-app --cwd $(pwd)",

      "echo ✅ [4/6] Checking port 3000...",
      "lsof -i:3000 || echo ⚠️ Port 3000 not open yet",
      
      "echo ✅ [5/6] Checking Nginx SSL config...",
      "test -f /etc/nginx/conf.d/ssl.conf && echo ✅ Found ssl.conf || echo ⚠️ Missing ssl.conf",

      "echo ✅ [6/6] Deployment finished on ${INSTANCE_ID}"
    ]' \
    --output text
done

# === [6/7] Done ===
echo "✅ [6/7] Deployment triggered to all instances"

# === [7/7] Complete ===
echo "✅ [7/7] Done!"
