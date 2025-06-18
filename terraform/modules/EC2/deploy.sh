#!/bin/bash


set -e

echo "🚀 Starting EC2 deployment"

# ==== Config ====
AWS_REGION=${AWS_REGION:-us-east-2}
TF_STATE_BUCKET=${TF_STATE_BUCKET:-vj-test-benvolate}
EC2_TFSTATE_KEY="EC2/terraform.tfstate"
ZIP_NAME="nodejs-app.zip"
ZIP_S3_KEY="nodejs/nodejs-app.zip"

# 👉 UPDATED: new repo
GITHUB_REPO="https://github.com/VidyaranyaRJ/benov.git"
APP_FOLDER="benov"

# ==== Clone Repo ====
echo "📥 Cloning Node.js app from GitHub..."
rm -rf $APP_FOLDER
git clone $GITHUB_REPO
[[ -d "$APP_FOLDER/Nodejs" ]] || { echo "❌ Nodejs folder not found in repo"; exit 1; }

# ==== Validate App ====
echo "🔍 Verifying application source..."
[[ -s "$APP_FOLDER/Nodejs/index.js" ]] && echo "✅ App file found and not empty" || { echo "❌ App file missing or empty"; exit 1; }

# ==== Zip App ====
echo "📦 Zipping Node.js app..."
rm -f $ZIP_NAME
cd $APP_FOLDER/Nodejs
zip -r ../../$ZIP_NAME .
cd ../..
ls -lh $ZIP_NAME

# ==== Upload to S3 ====
echo "☁️ Uploading files to S3..."
aws s3 cp $ZIP_NAME s3://$TF_STATE_BUCKET/$ZIP_S3_KEY --region $AWS_REGION
aws s3 cp scripts/node-deploy.sh s3://$TF_STATE_BUCKET/scripts/node-deploy.sh --region $AWS_REGION

# ==== Terraform EC2 ====
echo "📐 Terraform Init & Apply for EC2..."
cd terraform/modules/EC2
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$EC2_TFSTATE_KEY" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="encrypt=true"

terraform plan -input=false -out=tfplan
terraform apply -auto-approve tfplan

# # # === Destroy resources ===
# terraform destroy -auto-approve


cd ../../..

# ==== Extract EC2 Instance IDs ====
echo "🔍 Extracting EC2 instance IDs..."
aws s3 cp s3://$TF_STATE_BUCKET/$EC2_TFSTATE_KEY tfstate.json --region $AWS_REGION

INSTANCE_IDS=$(jq -r '.resources[] | select(.type == "aws_instance") | .instances[].attributes.id' tfstate.json 2>/dev/null || echo "")
if [ -z "$INSTANCE_IDS" ]; then
  echo "❌ No EC2 instance IDs found."
  exit 1
fi

echo "✅ Found EC2 instance IDs: $INSTANCE_IDS"
sleep 60

# ==== Deploy App via SSM ====
echo "🚀 Deploying Node.js app on EC2s..."
for INSTANCE_ID in $INSTANCE_IDS; do
  echo "👉 Deploying to $INSTANCE_ID"
  CMD_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=[
      "aws s3 cp s3://'"$TF_STATE_BUCKET"'/scripts/node-deploy.sh /tmp/node-deploy.sh",
      "chmod +x /tmp/node-deploy.sh",
      "bash /tmp/node-deploy.sh"
    ]' \
    --region $AWS_REGION \
    --query "Command.CommandId" \
    --output text)

  echo "✅ Command sent to $INSTANCE_ID: $CMD_ID"

  for i in {1..30}; do
    STATUS=$(aws ssm get-command-invocation \
      --command-id "$CMD_ID" \
      --instance-id "$INSTANCE_ID" \
      --region "$AWS_REGION" \
      --query "Status" \
      --output text 2>/dev/null || echo "Pending")

    echo "Status on $INSTANCE_ID: $STATUS"

    if [[ "$STATUS" == "Success" ]]; then
      echo "✅ Deployment succeeded on $INSTANCE_ID"
      break
    elif [[ "$STATUS" == "Failed" ]]; then
      echo "❌ Deployment failed on $INSTANCE_ID"
      break
    fi
    sleep 10
  done
done

# ==== Configure NGINX ==== 
echo "⚙️ Configuring NGINX on EC2s..."
for INSTANCE_ID in $INSTANCE_IDS; do
  echo "Configuring NGINX on $INSTANCE_ID"

  CMD_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=[
      "sudo dnf install -y nginx", 
      "sudo systemctl enable nginx", 
      "sudo systemctl start nginx", 
      "sudo bash -c \"cat > /etc/nginx/conf.d/nodeapp.conf <<'\''CONFIG'\''\nserver {\n  listen 80;\n  server_name _;\n  location / {\n    proxy_pass http://localhost:3000;\n    proxy_http_version 1.1;\n    proxy_set_header Upgrade \$http_upgrade;\n    proxy_set_header Connection '\''upgrade'\'';\n    proxy_set_header Host \$host;\n    proxy_cache_bypass \$http_upgrade;\n  }\n}\nCONFIG\"",
      "sudo rm -f /etc/nginx/conf.d/default.conf",
      "sudo nginx -t && sudo systemctl reload nginx"
    ]' \
    --region "$AWS_REGION" \
    --query "Command.CommandId" \
    --output text)


  for _ in {1..10}; do
    STATUS=$(aws ssm get-command-invocation \
      --command-id "$CMD_ID" \
      --instance-id "$INSTANCE_ID" \
      --region "$AWS_REGION" \
      --query "Status" \
      --output text 2>/dev/null || echo "Pending")

    echo "Nginx status on $INSTANCE_ID: $STATUS"

    if [[ "$STATUS" == "Success" ]]; then
      echo "✅ NGINX configured on $INSTANCE_ID"
      break
    elif [[ "$STATUS" == "Failed" ]]; then
      echo "❌ NGINX config failed on $INSTANCE_ID"
      break
    fi
    sleep 5
  done
done
