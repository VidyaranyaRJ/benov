#!/bin/bash
set -e

ENV="$1"
ZIP_NAME="nodejs-app.zip"
S3_BUCKET="vj-test-benvolate"
S3_KEY="nodejs/${ZIP_NAME}"
NODE_DIR="Nodejs"

echo "📦 Zipping Node.js app..."
cd "$NODE_DIR"
zip -r ../$ZIP_NAME . > /dev/null
cd ..

echo "📤 Uploading to S3..."
aws s3 cp "$ZIP_NAME" "s3://${S3_BUCKET}/${S3_KEY}"

echo "🚀 Finding EC2s tagged with Env=$ENV..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*-${ENV}" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

for ID in $INSTANCE_IDS; do
  echo "🔧 Triggering deploy on $ID"
  aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --comment "Deploy Node.js to $ID" \
    --instance-ids "$ID" \
    --parameters commands=["/bin/bash /home/ec2-user/node-deploy.sh $ENV"] \
    --region us-east-2
done

echo "✅ Deployment triggered to $ENV environment"
