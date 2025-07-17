#!/bin/bash
set -e

echo "🚀 Starting EC2 deployment with full debug..."

# === Detect Environment ===
if [ -n "$1" ]; then
  ENVIRONMENT="$1"
elif [ -n "$ENVIRONMENT" ]; then
  :
else
  echo "Usage: deploy.sh <environment> or set ENVIRONMENT"
  exit 1
fi

# === Config ===
AWS_REGION=${AWS_REGION:-us-east-2}
S3_BUCKET=${S3_BUCKET:-vj-test-benvolate}
MODULE="Nodejs"
ZIP_NAME="nodejs-app.zip"
S3_ZIP_PATH="nodejs/${ENVIRONMENT}/$ZIP_NAME"
SSH_KEY_NAME=${SSH_KEY_NAME:-vj-Benevolate.pem}
SSH_USER=ec2-user
GITHUB_REPO="https://github.com/VidyaranyaRJ/benov.git"

# === 1. Confirm ZIP Exists in S3 ===
echo "🔍 Checking if ZIP exists in S3..."
if aws s3 ls s3://${S3_BUCKET}/${S3_ZIP_PATH} --region $AWS_REGION >/dev/null; then
  echo "✅ Found ZIP in S3: ${S3_ZIP_PATH}"
else
  echo "❌ ZIP not found in S3!"
  exit 1
fi

# === 2. Get EC2 Instance IDs ===
echo "🔍 Fetching EC2 instances with Name ending in -${ENVIRONMENT}..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $AWS_REGION \
  --filters "Name=tag:Name,Values=*-dev" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)


if [ -z "$INSTANCE_IDS" ]; then
  echo "❌ No EC2 instances found!"
  exit 1
fi
echo "✅ Found EC2s: $INSTANCE_IDS"

# === 3. Check SSM is available ===
echo "🔍 Verifying SSM connectivity..."
for INSTANCE_ID in $INSTANCE_IDS; do
  STATUS=$(aws ssm describe-instance-information \
    --region $AWS_REGION \
    --query "InstanceInformationList[?InstanceId=='$INSTANCE_ID'].PingStatus" \
    --output text)
  if [ "$STATUS" != "Online" ]; then
    echo "❌ SSM is not online for $INSTANCE_ID"
    exit 1
  fi
  echo "✅ SSM is online for $INSTANCE_ID"
done

# === 4. Deploy to Each EC2 via SSM ===
for INSTANCE_ID in $INSTANCE_IDS; do
  echo "🚀 Deploying to $INSTANCE_ID..."

  aws ssm send-command \
  --region $AWS_REGION \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy Node.js App via SSM" \
  --instance-ids "$INSTANCE_ID" \
  --parameters commands="$(cat <<EOF
[
  "echo '✅ [1/7] Downloading app ZIP from S3...'",
  "aws s3 cp s3://$S3_BUCKET/$S3_ZIP_PATH /tmp/$ZIP_NAME --region $AWS_REGION",

  "echo '✅ [2/7] Unzipping to /mnt/efs/code/app...'",
  "sudo rm -rf /mnt/efs/code/app",
  "mkdir -p /mnt/efs/code/app",
  "unzip -o /tmp/$ZIP_NAME -d /mnt/efs/code/app",

  "echo '✅ [3/7] Running node-deploy.sh...'",
  "chmod +x /mnt/efs/code/app/node-deploy.sh",
  "bash /mnt/efs/code/app/node-deploy.sh",

  "echo '✅ [4/7] Checking PM2 process...'",
  "pm2 list | grep nodejs-app || echo '⚠️ nodejs-app not running via PM2'",

  "echo '✅ [5/7] Checking if port 3000 is open...'",
  "lsof -i:3000 || echo '✅ Port 3000 is free'",

  "echo '✅ [6/7] Done deployment on $INSTANCE_ID'"
]
EOF
)" \
  --output text

done

echo ""
echo "✅ Deployment triggered on all instances with full debug"
