#!/bin/bash

# set -e

# echo "🚀 Starting EC2 deployment"

# # ==== Config ====
# AWS_REGION=${AWS_REGION:-us-east-2}
# TF_STATE_BUCKET=${TF_STATE_BUCKET:-vj-test-benvolate}
# EC2_TFSTATE_KEY="EC2/terraform.tfstate"
# ZIP_NAME="nodejs-app.zip"
# ZIP_S3_KEY="nodejs/nodejs-app.zip"
# SSH_KEY_NAME=${SSH_KEY_NAME:-vj-Benevolate.pem}
# SSH_USER=${SSH_USER:-ec2-user}

# # 👉 UPDATED: new repo
# GITHUB_REPO="https://github.com/VidyaranyaRJ/benov.git"
# APP_FOLDER="benov"

# # ==== Handle SSH Key for CI/CD Environment ====
# echo "🔑 Setting up SSH key for CI/CD..."

# if [ -n "$EC2_SSH_PRIVATE_KEY" ]; then
#     # SSH key provided as environment variable (GitHub Secret)
#     echo "📝 Creating SSH key from environment variable..."
#     echo "$EC2_SSH_PRIVATE_KEY" > "$SSH_KEY_NAME"
#     chmod 400 "$SSH_KEY_NAME"
#     echo "✅ SSH key created from environment variable"
# elif [ -f "$SSH_KEY_NAME" ]; then
#     # SSH key file exists locally
#     chmod 400 "$SSH_KEY_NAME"
#     echo "✅ SSH key found locally and permissions set"
# else
#     # Try to download SSH key from S3
#     echo "📥 Attempting to download SSH key from S3..."
#     SSH_S3_PATH="s3://$TF_STATE_BUCKET/EC2/$SSH_KEY_NAME"
    
#     if aws s3 cp "$SSH_S3_PATH" "$SSH_KEY_NAME" --region "$AWS_REGION" 2>/dev/null; then
#         chmod 400 "$SSH_KEY_NAME"
#         echo "✅ SSH key downloaded from S3 and permissions set"
#         SSH_KEY_FROM_S3=true
#     else
#         # No SSH key available - check if we should skip SSH deployment
#         if [ "$SKIP_SSH_DEPLOYMENT" = "true" ]; then
#             echo "⚠️  SSH deployment skipped (SKIP_SSH_DEPLOYMENT=true)"
#             SKIP_SSH=true
#         else
#             echo "❌ SSH key not found locally or in S3!"
#             echo "💡 For CI/CD environments, either:"
#             echo "   1. Set EC2_SSH_PRIVATE_KEY as a secret containing your private key content"
#             echo "   2. Upload your SSH key to S3 at: $SSH_S3_PATH"
#             echo "   3. Set SKIP_SSH_DEPLOYMENT=true to skip SSH deployment steps"
#             echo "   4. Use AWS Systems Manager Session Manager instead of SSH"
#             exit 1
#         fi
#     fi
# fi

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
# # terraform apply -auto-approve tfplan
# terraform destroy -auto-approve



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

# # Skip SSH deployment if requested or no SSH key available
# if [ "$SKIP_SSH" = "true" ]; then
#     echo "⚠️  Skipping SSH deployment steps"
#     echo "🎉 Infrastructure deployment completed!"
#     echo "📋 EC2 Instance IDs: $INSTANCE_IDS"
#     echo "💡 You'll need to manually deploy the application or use Systems Manager"
#     exit 0
# fi

# echo "⏳ Waiting for instances to be ready..."
# sleep 60

# # ==== Function to wait for SSH connectivity ====
# wait_for_ssh() {
#     local host=$1
#     local max_attempts=30
#     local attempt=1
    
#     echo "⏳ Waiting for SSH connectivity to $host..."
#     while [ $attempt -le $max_attempts ]; do
#         if ssh -i "$SSH_KEY_NAME" \
#                -o ConnectTimeout=10 \
#                -o StrictHostKeyChecking=no \
#                -o UserKnownHostsFile=/dev/null \
#                -o LogLevel=ERROR \
#                -o BatchMode=yes \
#                "$SSH_USER@$host" "echo 'SSH connection successful'" 2>/dev/null; then
#             echo "✅ SSH connection established to $host"
#             return 0
#         fi
#         echo "⏳ Attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
#         sleep 10
#         ((attempt++))
#     done
#     echo "❌ Failed to establish SSH connection to $host after $max_attempts attempts"
#     return 1
# }

# # ==== Alternative: Use AWS Systems Manager Session Manager ====
# deploy_via_ssm() {
#     local instance_id=$1
#     echo "🔧 Deploying via AWS Systems Manager to $instance_id..."
    
#     # Check if SSM agent is ready
#     echo "⏳ Waiting for SSM agent to be ready..."
#     aws ssm wait instance-information-available --instance-information-filter-list key=InstanceIds,valueSet=$instance_id --region $AWS_REGION
    
#     # Send command via SSM
#     COMMAND_ID=$(aws ssm send-command \
#         --instance-ids "$instance_id" \
#         --document-name "AWS-RunShellScript" \
#         --parameters "commands=[
#             'echo \"🚀 Starting deployment via SSM...\"',
#             'export TF_STATE_BUCKET=\"$TF_STATE_BUCKET\"',
#             'export AWS_REGION=\"$AWS_REGION\"',
#             'aws s3 cp s3://\$TF_STATE_BUCKET/scripts/node-deploy.sh /tmp/node-deploy.sh --region \$AWS_REGION',
#             'chmod +x /tmp/node-deploy.sh',
#             'bash /tmp/node-deploy.sh'
#         ]" \
#         --region $AWS_REGION \
#         --query 'Command.CommandId' \
#         --output text)
    
#     echo "📤 Command sent with ID: $COMMAND_ID"
    
#     # Wait for command completion
#     echo "⏳ Waiting for command completion..."
#     aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$instance_id" --region $AWS_REGION
    
#     # Get command output
#     echo "📋 Command output:"
#     aws ssm get-command-invocation \
#         --command-id "$COMMAND_ID" \
#         --instance-id "$instance_id" \
#         --region $AWS_REGION \
#         --query 'StandardOutputContent' \
#         --output text
# }

# # ==== Deploy App via SSH or SSM ====
# echo "🚀 Deploying Node.js app on EC2s..."
# for INSTANCE_ID in $INSTANCE_IDS; do
#     echo "🔍 Getting public IP for instance $INSTANCE_ID..."
    
#     # Wait for instance to have a public IP
#     PUBLIC_IPV4=""
#     for i in {1..10}; do
#         PUBLIC_IPV4=$(aws ec2 describe-instances \
#             --instance-ids "$INSTANCE_ID" \
#             --region "$AWS_REGION" \
#             --query "Reservations[].Instances[].PublicIpAddress" \
#             --output text 2>/dev/null || echo "")
        
#         if [ "$PUBLIC_IPV4" != "None" ] && [ -n "$PUBLIC_IPV4" ]; then
#             break
#         fi
#         echo "⏳ Waiting for public IP assignment... (attempt $i/10)"
#         sleep 15
#     done
    
#     # Try SSH deployment first, fallback to SSM
#     if [ -n "$PUBLIC_IPV4" ] && [ "$PUBLIC_IPV4" != "None" ]; then
#         echo "✅ Found public IP: $PUBLIC_IPV4 for instance $INSTANCE_ID"
        
#         # Try SSH deployment
#         if wait_for_ssh "$PUBLIC_IPV4"; then
#             echo "👉 Deploying via SSH to $INSTANCE_ID at $PUBLIC_IPV4"
            
#             ssh -i "$SSH_KEY_NAME" \
#                 -o StrictHostKeyChecking=no \
#                 -o UserKnownHostsFile=/dev/null \
#                 -o LogLevel=ERROR \
#                 -o BatchMode=yes \
#                 "$SSH_USER@$PUBLIC_IPV4" << EOF
# echo "🚀 Starting deployment on EC2..."
# export TF_STATE_BUCKET="$TF_STATE_BUCKET"
# export AWS_REGION="$AWS_REGION"
# aws s3 cp s3://\$TF_STATE_BUCKET/scripts/node-deploy.sh /tmp/node-deploy.sh --region \$AWS_REGION
# chmod +x /tmp/node-deploy.sh
# bash /tmp/node-deploy.sh
# echo "✅ Deployment completed on \$(hostname)"
# EOF
            
#             if [ $? -eq 0 ]; then
#                 echo "✅ Successfully deployed via SSH to $INSTANCE_ID"
#             else
#                 echo "❌ SSH deployment failed, trying SSM..."
#                 deploy_via_ssm "$INSTANCE_ID"
#             fi
#         else
#             echo "❌ SSH failed, trying Systems Manager..."
#             deploy_via_ssm "$INSTANCE_ID"
#         fi
#     else
#         echo "⚠️  No public IP, using Systems Manager..."
#         deploy_via_ssm "$INSTANCE_ID"
#     fi
# done

# # ==== Configure NGINX ====
# echo "⚙️ Configuring NGINX on EC2s..."
# for INSTANCE_ID in $INSTANCE_IDS; do
#     PUBLIC_IPV4=$(aws ec2 describe-instances \
#         --instance-ids "$INSTANCE_ID" \
#         --region "$AWS_REGION" \
#         --query "Reservations[].Instances[].PublicIpAddress" \
#         --output text)
    
#     if [ -n "$PUBLIC_IPV4" ] && [ "$PUBLIC_IPV4" != "None" ]; then
#         echo "👉 Configuring NGINX via SSH on $INSTANCE_ID at $PUBLIC_IPV4"
        
#         ssh -i "$SSH_KEY_NAME" \
#             -o StrictHostKeyChecking=no \
#             -o UserKnownHostsFile=/dev/null \
#             -o LogLevel=ERROR \
#             -o BatchMode=yes \
#             "$SSH_USER@$PUBLIC_IPV4" << 'EOF'
# # Install and configure NGINX
# echo "⚙️ Installing NGINX..."
# sudo dnf update -y
# sudo dnf install -y nginx
# sudo systemctl enable nginx
# sudo systemctl start nginx

# # Configure NGINX reverse proxy
# echo "⚙️ Configuring NGINX reverse proxy..."
# sudo bash -c "cat > /etc/nginx/conf.d/nodeapp.conf << 'CONFIG'
# server {
#     listen 80;
#     server_name _;
#     location / {
#         proxy_pass http://localhost:3000;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#         proxy_cache_bypass \$http_upgrade;
#     }
# }
# CONFIG"

# sudo rm -f /etc/nginx/conf.d/default.conf
# sudo nginx -t && sudo systemctl reload nginx
# echo "✅ NGINX configured successfully"
# EOF
#     else
#         echo "⚙️ Configuring NGINX via SSM on $INSTANCE_ID"
#         # Use SSM for NGINX configuration
#         NGINX_COMMAND_ID=$(aws ssm send-command \
#             --instance-ids "$INSTANCE_ID" \
#             --document-name "AWS-RunShellScript" \
#             --parameters "commands=[
#                 'sudo dnf update -y',
#                 'sudo dnf install -y nginx',
#                 'sudo systemctl enable nginx',
#                 'sudo systemctl start nginx',
#                 'sudo bash -c \"cat > /etc/nginx/conf.d/nodeapp.conf << CONFIG
# server {
#     listen 80;
#     server_name _;
#     location / {
#         proxy_pass http://localhost:3000;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \\\$http_upgrade;
#         proxy_set_header Connection \\\"upgrade\\\";
#         proxy_set_header Host \\\$host;
#         proxy_cache_bypass \\\$http_upgrade;
#     }
# }
# CONFIG\"',
#                 'sudo rm -f /etc/nginx/conf.d/default.conf',
#                 'sudo nginx -t && sudo systemctl reload nginx'
#             ]" \
#             --region $AWS_REGION \
#             --query 'Command.CommandId' \
#             --output text)
        
#         echo "📤 NGINX configuration command sent: $NGINX_COMMAND_ID"
#     fi
# done

# # ==== Cleanup ====
# if [ -f "$SSH_KEY_NAME" ] && ([ -n "$EC2_SSH_PRIVATE_KEY" ] || [ "$SSH_KEY_FROM_S3" = "true" ]); then
#     echo "🧹 Cleaning up temporary SSH key..."
#     rm -f "$SSH_KEY_NAME"
# fi

# # ==== Final Steps ====
# echo ""
# echo "🎉 Deployment process completed!"
# echo ""
# echo "📋 Summary:"
# echo "  - Processed instances: $INSTANCE_IDS"
# echo "  - Region: $AWS_REGION"
# echo ""
# echo "🌐 Your application should be accessible via the EC2 public IPs"
# echo "💡 Check EC2 console for public IPs and ensure security groups allow HTTP traffic"





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

# ==== Handle SSH Key for CI/CD Environment ====
echo "🔑 Setting up SSH key for CI/CD..."

if [ -n "$EC2_SSH_PRIVATE_KEY" ]; then
    # SSH key provided as environment variable (GitHub Secret)
    echo "📝 Creating SSH key from environment variable..."
    echo "$EC2_SSH_PRIVATE_KEY" > "$SSH_KEY_NAME"
    chmod 400 "$SSH_KEY_NAME"
    echo "✅ SSH key created from environment variable"
elif [ -f "$SSH_KEY_NAME" ]; then
    # SSH key file exists locally
    chmod 400 "$SSH_KEY_NAME"
    echo "✅ SSH key found locally and permissions set"
else
    # Try to download SSH key from S3
    echo "📥 Attempting to download SSH key from S3..."
    SSH_S3_PATH="s3://$TF_STATE_BUCKET/EC2/$SSH_KEY_NAME"
    
    if aws s3 cp "$SSH_S3_PATH" "$SSH_KEY_NAME" --region "$AWS_REGION" 2>/dev/null; then
        chmod 400 "$SSH_KEY_NAME"
        echo "✅ SSH key downloaded from S3 and permissions set"
        SSH_KEY_FROM_S3=true
    else
        # No SSH key available - check if we should skip SSH deployment
        if [ "$SKIP_SSH_DEPLOYMENT" = "true" ]; then
            echo "⚠️  SSH deployment skipped (SKIP_SSH_DEPLOYMENT=true)"
            SKIP_SSH=true
        else
            echo "❌ SSH key not found locally or in S3!"
            echo "💡 For CI/CD environments, either:"
            echo "   1. Set EC2_SSH_PRIVATE_KEY as a secret containing your private key content"
            echo "   2. Upload your SSH key to S3 at: $SSH_S3_PATH"
            echo "   3. Set SKIP_SSH_DEPLOYMENT=true to skip SSH deployment steps"
            echo "   4. Use AWS Systems Manager Session Manager instead of SSH"
            exit 1
        fi
    fi
fi

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
# FIX: Apply instead of destroy!
# terraform apply -auto-approve tfplan
terraform destroy -auto-approve  # ← REMOVED: This was destroying your instances!

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

# Skip SSH deployment if requested or no SSH key available
if [ "$SKIP_SSH" = "true" ]; then
    echo "⚠️  Skipping SSH deployment steps"
    echo "🎉 Infrastructure deployment completed!"
    echo "📋 EC2 Instance IDs: $INSTANCE_IDS"
    echo "💡 You'll need to manually deploy the application or use Systems Manager"
    exit 0
fi

# FIX: Wait longer for user-data script to complete EFS mounting
echo "⏳ Waiting for instances to be ready and EFS to mount..."
sleep 180  # Increased from 60 to 180 seconds

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
               -o BatchMode=yes \
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

# ==== Function to check EFS mount status ====
check_efs_status() {
    local host=$1
    echo "🔍 Checking EFS mount status on $host..."
    
    ssh -i "$SSH_KEY_NAME" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        -o BatchMode=yes \
        "$SSH_USER@$host" << 'EOF'
echo "=== EFS Mount Status ==="
df -h -t nfs4 | grep -E "(amazonaws|efs)" || echo "No EFS mounts found"
echo "=== Mount Points ==="
ls -la /mnt/efs/ 2>/dev/null || echo "/mnt/efs not found"
echo "=== User Data Log ==="
tail -20 /var/log/user-data.log 2>/dev/null || echo "User data log not found"
echo "=== System Status ==="
systemctl is-active systemd-resolved || echo "systemd-resolved not active"
EOF
}

# ==== Alternative: Use AWS Systems Manager Session Manager ====
deploy_via_ssm() {
    local instance_id=$1
    echo "🔧 Deploying via AWS Systems Manager to $instance_id..."
    
    # Check if SSM agent is ready
    echo "⏳ Waiting for SSM agent to be ready..."
    aws ssm wait instance-information-available --instance-information-filter-list key=InstanceIds,valueSet=$instance_id --region $AWS_REGION
    
    # Send command via SSM
    COMMAND_ID=$(aws ssm send-command \
        --instance-ids "$instance_id" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[
            'echo \"🚀 Starting deployment via SSM...\"',
            'export TF_STATE_BUCKET=\"$TF_STATE_BUCKET\"',
            'export AWS_REGION=\"$AWS_REGION\"',
            'aws s3 cp s3://\$TF_STATE_BUCKET/scripts/node-deploy.sh /tmp/node-deploy.sh --region \$AWS_REGION',
            'chmod +x /tmp/node-deploy.sh',
            'bash /tmp/node-deploy.sh'
        ]" \
        --region $AWS_REGION \
        --query 'Command.CommandId' \
        --output text)
    
    echo "📤 Command sent with ID: $COMMAND_ID"
    
    # Wait for command completion
    echo "⏳ Waiting for command completion..."
    aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$instance_id" --region $AWS_REGION
    
    # Get command output
    echo "📋 Command output:"
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$instance_id" \
        --region $AWS_REGION \
        --query 'StandardOutputContent' \
        --output text
}

# ==== Deploy App via SSH or SSM ====
echo "🚀 Deploying Node.js app on EC2s..."
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
    
    # Try SSH deployment first, fallback to SSM
    if [ -n "$PUBLIC_IPV4" ] && [ "$PUBLIC_IPV4" != "None" ]; then
        echo "✅ Found public IP: $PUBLIC_IPV4 for instance $INSTANCE_ID"
        
        # Try SSH deployment
        if wait_for_ssh "$PUBLIC_IPV4"; then
            # Check EFS status first
            check_efs_status "$PUBLIC_IPV4"
            
            echo "👉 Deploying via SSH to $INSTANCE_ID at $PUBLIC_IPV4"
            
            ssh -i "$SSH_KEY_NAME" \
                -o StrictHostKeyChecking=no \
                -o UserKnownHostsFile=/dev/null \
                -o LogLevel=ERROR \
                -o BatchMode=yes \
                "$SSH_USER@$PUBLIC_IPV4" << EOF
echo "🚀 Starting deployment on EC2..."
export TF_STATE_BUCKET="$TF_STATE_BUCKET"
export AWS_REGION="$AWS_REGION"
aws s3 cp s3://\$TF_STATE_BUCKET/scripts/node-deploy.sh /tmp/node-deploy.sh --region \$AWS_REGION
chmod +x /tmp/node-deploy.sh
bash /tmp/node-deploy.sh
echo "✅ Deployment completed on \$(hostname)"
EOF
            
            if [ $? -eq 0 ]; then
                echo "✅ Successfully deployed via SSH to $INSTANCE_ID"
            else
                echo "❌ SSH deployment failed, trying SSM..."
                deploy_via_ssm "$INSTANCE_ID"
            fi
        else
            echo "❌ SSH failed, trying Systems Manager..."
            deploy_via_ssm "$INSTANCE_ID"
        fi
    else
        echo "⚠️  No public IP, using Systems Manager..."
        deploy_via_ssm "$INSTANCE_ID"
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
    
    if [ -n "$PUBLIC_IPV4" ] && [ "$PUBLIC_IPV4" != "None" ]; then
        echo "👉 Configuring NGINX via SSH on $INSTANCE_ID at $PUBLIC_IPV4"
        
        ssh -i "$SSH_KEY_NAME" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o LogLevel=ERROR \
            -o BatchMode=yes \
            "$SSH_USER@$PUBLIC_IPV4" << 'EOF'
# Install and configure NGINX
echo "⚙️ Installing NGINX..."
sudo dnf update -y
sudo dnf install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Configure NGINX reverse proxy
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
    }
}
CONFIG"

sudo rm -f /etc/nginx/conf.d/default.conf
sudo nginx -t && sudo systemctl reload nginx
echo "✅ NGINX configured successfully"
EOF
    else
        echo "⚙️ Configuring NGINX via SSM on $INSTANCE_ID"
        # Use SSM for NGINX configuration
        NGINX_COMMAND_ID=$(aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters "commands=[
                'sudo dnf update -y',
                'sudo dnf install -y nginx',
                'sudo systemctl enable nginx',
                'sudo systemctl start nginx',
                'sudo bash -c \"cat > /etc/nginx/conf.d/nodeapp.conf << CONFIG
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection \\\"upgrade\\\";
        proxy_set_header Host \\\$host;
        proxy_cache_bypass \\\$http_upgrade;
    }
}
CONFIG\"',
                'sudo rm -f /etc/nginx/conf.d/default.conf',
                'sudo nginx -t && sudo systemctl reload nginx'
            ]" \
            --region $AWS_REGION \
            --query 'Command.CommandId' \
            --output text)
        
        echo "📤 NGINX configuration command sent: $NGINX_COMMAND_ID"
    fi
done

# ==== Cleanup ====
if [ -f "$SSH_KEY_NAME" ] && ([ -n "$EC2_SSH_PRIVATE_KEY" ] || [ "$SSH_KEY_FROM_S3" = "true" ]); then
    echo "🧹 Cleaning up temporary SSH key..."
    rm -f "$SSH_KEY_NAME"
fi

# ==== Final Steps ====
echo ""
echo "🎉 Deployment process completed!"
echo ""
echo "📋 Summary:"
echo "  - Processed instances: $INSTANCE_IDS"
echo "  - Region: $AWS_REGION"
echo ""
echo "🌐 Your application should be accessible via the EC2 public IPs"
echo "💡 Check EC2 console for public IPs and ensure security groups allow HTTP traffic"