#!/bin/bash


# set -e

# echo "🚀 Starting EC2 deployment"

# # ==== Config ====
# AWS_REGION=${AWS_REGION:-us-east-2}
# TF_STATE_BUCKET=${TF_STATE_BUCKET:-vj-test-benvolate}
# EC2_TFSTATE_KEY="EC2/terraform.tfstate"
# ZIP_NAME="nodejs-app.zip"
# ZIP_S3_KEY="nodejs/nodejs-app.zip"

# # 👉 UPDATED: new repo
# GITHUB_REPO="https://github.com/VidyaranyaRJ/benov.git"
# APP_FOLDER="benov"

# # ==== Clone Repo ====
# echo "📥 Cloning Node.js app from GitHub..."
# rm -rf $APP_FOLDER
# git clone $GITHUB_REPO
# [[ -d "$APP_FOLDER/Nodejs" ]] || { echo "❌ Nodejs folder not found in repo"; exit 1; }

# # ==== Validate App ====
# echo "🔍 Verifying application source..."
# [[ -s "$APP_FOLDER/Nodejs/index.js" ]] && echo "✅ App file found and not empty" || { echo "❌ App file missing or empty"; exit 1; }

# # ==== Zip App ====
# echo "📦 Zipping Node.js app..."
# rm -f $ZIP_NAME
# cd $APP_FOLDER/Nodejs
# zip -r ../../$ZIP_NAME .
# cd ../..
# ls -lh $ZIP_NAME

# # ==== Upload to S3 ====
# echo "☁️ Uploading files to S3..."
# aws s3 cp $ZIP_NAME s3://$TF_STATE_BUCKET/$ZIP_S3_KEY --region $AWS_REGION
# aws s3 cp scripts/node-deploy.sh s3://$TF_STATE_BUCKET/scripts/node-deploy.sh --region $AWS_REGION

# # ==== Terraform EC2 ====
# echo "📐 Terraform Init & Apply for EC2..."
# cd terraform/modules/EC2
# terraform init \
#   -backend-config="bucket=$TF_STATE_BUCKET" \
#   -backend-config="key=$EC2_TFSTATE_KEY" \
#   -backend-config="region=$AWS_REGION" \
#   -backend-config="encrypt=true"

# terraform plan -input=false -out=tfplan
# terraform apply -auto-approve tfplan

# # # # === Destroy resources ===
# # terraform destroy -auto-approve


# cd ../../..

# # ==== Extract EC2 Instance IDs ====
# echo "🔍 Extracting EC2 instance IDs..."
# aws s3 cp s3://$TF_STATE_BUCKET/$EC2_TFSTATE_KEY tfstate.json --region $AWS_REGION

# INSTANCE_IDS=$(jq -r '.resources[] | select(.type == "aws_instance") | .instances[].attributes.id' tfstate.json 2>/dev/null || echo "")
# if [ -z "$INSTANCE_IDS" ]; then
#   echo "❌ No EC2 instance IDs found."
#   exit 1
# fi

# echo "✅ Found EC2 instance IDs: $INSTANCE_IDS"
# sleep 60

# # ==== Deploy App via SSM ====
# echo "🚀 Deploying Node.js app on EC2s..."
# for INSTANCE_ID in $INSTANCE_IDS; do
#   echo "👉 Deploying to $INSTANCE_ID"
#   CMD_ID=$(aws ssm send-command \
#     --instance-ids "$INSTANCE_ID" \
#     --document-name "AWS-RunShellScript" \
#     --parameters 'commands=[
#       "aws s3 cp s3://'"$TF_STATE_BUCKET"'/scripts/node-deploy.sh /tmp/node-deploy.sh",
#       "chmod +x /tmp/node-deploy.sh",
#       "bash /tmp/node-deploy.sh"
#     ]' \
#     --region $AWS_REGION \
#     --query "Command.CommandId" \
#     --output text)

#   echo "✅ Command sent to $INSTANCE_ID: $CMD_ID"

#   for i in {1..30}; do
#     STATUS=$(aws ssm get-command-invocation \
#       --command-id "$CMD_ID" \
#       --instance-id "$INSTANCE_ID" \
#       --region "$AWS_REGION" \
#       --query "Status" \
#       --output text 2>/dev/null || echo "Pending")

#     echo "Status on $INSTANCE_ID: $STATUS"

#     if [[ "$STATUS" == "Success" ]]; then
#       echo "✅ Deployment succeeded on $INSTANCE_ID"
#       break
#     elif [[ "$STATUS" == "Failed" ]]; then
#       echo "❌ Deployment failed on $INSTANCE_ID"
#       break
#     fi
#     sleep 10
#   done
# done

# # ==== Configure NGINX ==== 
# echo "⚙️ Configuring NGINX on EC2s..."
# for INSTANCE_ID in $INSTANCE_IDS; do
#   echo "Configuring NGINX on $INSTANCE_ID"

#   CMD_ID=$(aws ssm send-command \
#     --instance-ids "$INSTANCE_ID" \
#     --document-name "AWS-RunShellScript" \
#     --parameters 'commands=[
#       "sudo dnf install -y nginx", 
#       "sudo systemctl enable nginx", 
#       "sudo systemctl start nginx", 
#       "sudo bash -c \"cat > /etc/nginx/conf.d/nodeapp.conf <<'\''CONFIG'\''\nserver {\n  listen 80;\n  server_name _;\n  location / {\n    proxy_pass http://localhost:3000;\n    proxy_http_version 1.1;\n    proxy_set_header Upgrade \$http_upgrade;\n    proxy_set_header Connection '\''upgrade'\'';\n    proxy_set_header Host \$host;\n    proxy_cache_bypass \$http_upgrade;\n  }\n}\nCONFIG\"",
#       "sudo rm -f /etc/nginx/conf.d/default.conf",
#       "sudo nginx -t && sudo systemctl reload nginx"
#     ]' \
#     --region "$AWS_REGION" \
#     --query "Command.CommandId" \
#     --output text)


#   for _ in {1..10}; do
#     STATUS=$(aws ssm get-command-invocation \
#       --command-id "$CMD_ID" \
#       --instance-id "$INSTANCE_ID" \
#       --region "$AWS_REGION" \
#       --query "Status" \
#       --output text 2>/dev/null || echo "Pending")

#     echo "Nginx status on $INSTANCE_ID: $STATUS"

#     if [[ "$STATUS" == "Success" ]]; then
#       echo "✅ NGINX configured on $INSTANCE_ID"
#       break
#     elif [[ "$STATUS" == "Failed" ]]; then
#       echo "❌ NGINX config failed on $INSTANCE_ID"
#       break
#     fi
#     sleep 5
#   done
# done



#!/bin/bash

set -e

echo "🚀 Starting EC2 deployment"

# ==== Config ====
AWS_REGION=${AWS_REGION:-us-east-2}
TF_STATE_BUCKET=${TF_STATE_BUCKET:-vj-test-benvolate}
EC2_TFSTATE_KEY="EC2/terraform.tfstate"
ZIP_NAME="nodejs-app.zip"
ZIP_S3_KEY="nodejs/nodejs-app.zip"
SSH_KEY_NAME=${SSH_KEY_NAME:-vj-Benevolate.pem}
SSH_USER=${SSH_USER:-ec2-user}

# 👉 UPDATED: new repo
GITHUB_REPO="https://github.com/VidyaranyaRJ/benov.git"
APP_FOLDER="benov"

# ==== Validate SSH Key ====
echo "🔑 Checking SSH key..."
if [ ! -f "$SSH_KEY_NAME" ]; then
    echo "❌ SSH key file '$SSH_KEY_NAME' not found!"
    echo "💡 Make sure to:"
    echo "   1. Download your EC2 key pair from AWS console"
    echo "   2. Place it in the current directory as '$SSH_KEY_NAME'"
    echo "   3. Or set SSH_KEY_NAME environment variable to the correct path"
    exit 1
fi

# Set correct permissions for SSH key
chmod 400 "$SSH_KEY_NAME"
echo "✅ SSH key found and permissions set"

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
echo "⏳ Waiting for instances to be ready..."
sleep 60

# ==== Function to wait for SSH connectivity ====
wait_for_ssh() {
    local host=$1
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for SSH connectivity to $host..."
    while [ $attempt -le $max_attempts ]; do
        if ssh -i "$SSH_KEY_NAME" \
               -o ConnectTimeout=10 \
               -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o LogLevel=ERROR \
               "$SSH_USER@$host" "echo 'SSH connection successful'" 2>/dev/null; then
            echo "✅ SSH connection established to $host"
            return 0
        fi
        echo "⏳ Attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
        sleep 10
        ((attempt++))
    done
    echo "❌ Failed to establish SSH connection to $host after $max_attempts attempts"
    return 1
}

# ==== Deploy App via SSH ====
echo "🚀 Deploying Node.js app on EC2s via SSH..."
for INSTANCE_ID in $INSTANCE_IDS; do
    echo "🔍 Getting public IP for instance $INSTANCE_ID..."
    
    # Wait for instance to have a public IP
    PUBLIC_IPV4=""
    for i in {1..10}; do
        PUBLIC_IPV4=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$AWS_REGION" \
            --query "Reservations[].Instances[].PublicIpAddress" \
            --output text 2>/dev/null || echo "")
        
        if [ "$PUBLIC_IPV4" != "None" ] && [ -n "$PUBLIC_IPV4" ]; then
            break
        fi
        echo "⏳ Waiting for public IP assignment... (attempt $i/10)"
        sleep 15
    done
    
    if [ -z "$PUBLIC_IPV4" ] || [ "$PUBLIC_IPV4" = "None" ]; then
        echo "❌ No public IP found for $INSTANCE_ID after waiting"
        continue
    fi

    echo "✅ Found public IP: $PUBLIC_IPV4 for instance $INSTANCE_ID"
    
    # Wait for SSH to be available
    if ! wait_for_ssh "$PUBLIC_IPV4"; then
        echo "❌ Skipping deployment to $INSTANCE_ID due to SSH connectivity issues"
        continue
    fi
    
    echo "👉 Deploying to $INSTANCE_ID at $PUBLIC_IPV4"
    
    # Deploy the application
    ssh -i "$SSH_KEY_NAME" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$SSH_USER@$PUBLIC_IPV4" << EOF
echo "🚀 Starting deployment on EC2..."

# Export environment variables for the remote session
export TF_STATE_BUCKET="$TF_STATE_BUCKET"
export AWS_REGION="$AWS_REGION"

# Download and execute deployment script
echo "📥 Downloading deployment script..."
aws s3 cp s3://\$TF_STATE_BUCKET/scripts/node-deploy.sh /tmp/node-deploy.sh --region \$AWS_REGION
chmod +x /tmp/node-deploy.sh

echo "🎯 Executing deployment script..."
bash /tmp/node-deploy.sh

echo "✅ Deployment script completed on \$(hostname)"
EOF

    if [ $? -eq 0 ]; then
        echo "✅ Successfully deployed to $INSTANCE_ID"
    else
        echo "❌ Deployment failed for $INSTANCE_ID"
    fi
done

# ==== Configure NGINX ====
echo "⚙️ Configuring NGINX on EC2s..."
for INSTANCE_ID in $INSTANCE_IDS; do
    PUBLIC_IPV4=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query "Reservations[].Instances[].PublicIpAddress" \
        --output text)
    
    if [ -z "$PUBLIC_IPV4" ] || [ "$PUBLIC_IPV4" = "None" ]; then
        echo "❌ No public IP found for $INSTANCE_ID"
        continue
    fi

    echo "👉 Configuring NGINX on $INSTANCE_ID at $PUBLIC_IPV4"
    
    ssh -i "$SSH_KEY_NAME" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$SSH_USER@$PUBLIC_IPV4" << 'EOF'

# Install NGINX
echo "⚙️ Installing NGINX..."
sudo dnf update -y
sudo dnf install -y nginx

# Enable and start NGINX service
echo "🚀 Starting NGINX service..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Configure NGINX to reverse proxy to Node.js app
echo "⚙️ Configuring NGINX reverse proxy..."
sudo bash -c "cat > /etc/nginx/conf.d/nodeapp.conf << 'CONFIG'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
CONFIG"

# Remove default NGINX config if it exists
sudo rm -f /etc/nginx/conf.d/default.conf
sudo rm -f /etc/nginx/sites-enabled/default

# Test NGINX configuration
echo "🧪 Testing NGINX configuration..."
if sudo nginx -t; then
    echo "✅ NGINX configuration is valid"
    sudo systemctl reload nginx
    echo "✅ NGINX reloaded successfully"
else
    echo "❌ NGINX configuration test failed"
    exit 1
fi

# Check if Node.js app is running
echo "🔍 Checking Node.js application status..."
if pgrep -f "node.*index.js" > /dev/null; then
    echo "✅ Node.js application is running"
else
    echo "❌ Node.js application is not running"
fi

# Check NGINX status
echo "🔍 Checking NGINX status..."
sudo systemctl status nginx --no-pager

echo "✅ NGINX configuration completed on $(hostname)"
EOF

    if [ $? -eq 0 ]; then
        echo "✅ Successfully configured NGINX on $INSTANCE_ID"
        echo "🌐 Application should be accessible at: http://$PUBLIC_IPV4"
    else
        echo "❌ NGINX configuration failed for $INSTANCE_ID"
    fi
done

# ==== Final Steps ====
echo ""
echo "🎉 Deployment process completed!"
echo ""
echo "📋 Summary:"
echo "  - Processed instances: $INSTANCE_IDS"
echo "  - SSH Key used: $SSH_KEY_NAME"
echo "  - Region: $AWS_REGION"
echo ""
echo "🌐 Your application should be accessible via the public IPs listed above"
echo "💡 If you encounter issues, check the EC2 security groups allow HTTP (port 80) traffic"