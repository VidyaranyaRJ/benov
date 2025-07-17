#!/bin/bash
set -e

ENV="$1"
MODULE="Nodejs"
ZIP_NAME="nodejs-app.zip"
S3_BUCKET="vj-test-benvolate"
S3_BASE_KEY="nodejs/${ENV}"
LOCAL_ZIP_PATH="./${ZIP_NAME}"

echo "📦 Zipping Node.js app and deployment script..."
zip -r "${ZIP_NAME}" ${MODULE} node-deploy.sh -x "**/.git/*" > /dev/null

echo "📤 Uploading to S3..."
aws s3 cp "${ZIP_NAME}" "s3://${S3_BUCKET}/${S3_BASE_KEY}/"
aws s3 cp node-deploy.sh "s3://${S3_BUCKET}/${S3_BASE_KEY}/"

echo "✅ Upload complete. Verifying contents in S3:"
aws s3 ls "s3://${S3_BUCKET}/${S3_BASE_KEY}/"

echo ""
echo "🚀 Finding EC2 instances tagged with Env=${ENV}..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*-${ENV}" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "❌ No running EC2 instances found with tag Env=${ENV}"
  exit 1
fi

echo "✅ Found EC2 instance(s):"
for ID in $INSTANCE_IDS; do
  echo "   - $ID"
done

echo ""
echo "🔧 Sending SSM commands to trigger remote deployment..."

for ID in $INSTANCE_IDS; do
  echo ""
  echo "📡 Deploying to instance: $ID"

  aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy Node.js to $ID" \
  --instance-ids "$ID" \
  --parameters '{"commands":["echo 📥 Downloading node-deploy.sh from S3...","aws s3 cp s3://'${S3_BUCKET}'/'${S3_BASE_KEY}'/node-deploy.sh /home/ec2-user/node-deploy.sh","ls -l /home/ec2-user/node-deploy.sh || echo ❌ node-deploy.sh not found after copy","chmod +x /home/ec2-user/node-deploy.sh","echo 🚀 Executing node-deploy.sh for environment: '${ENV}'","sudo bash /home/ec2-user/node-deploy.sh '${ENV}'"]}' \
  --region us-east-2 \
  --output json
done

echo ""
echo "✅ All deployment commands triggered successfully for environment: $ENV"
