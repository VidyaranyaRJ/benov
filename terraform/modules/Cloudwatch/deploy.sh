#!/bin/bash
# set -e

# # === Configuration ===
# TF_STATE_BUCKET="vj-test-benvolate"
# TF_STATE_KEY="Cloudwatch/terraform.tfstate"
# AWS_REGION="us-east-2"
# TERRAFORM_DIR="$(dirname "$0")"

# echo ">>> Deploying Terraform for EFS from: $TERRAFORM_DIR"

# # === Initialize Terraform with backend config ===
# terraform -chdir="$TERRAFORM_DIR" init \
#   -backend-config="bucket=$TF_STATE_BUCKET" \
#   -backend-config="key=$TF_STATE_KEY" \
#   -backend-config="region=$AWS_REGION" \
#   -backend-config="encrypt=true"

# # === Plan and apply ===
# terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan
# terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan

# # # === Destroy resources ===
# # terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve






# set -e

# # === Configuration ===
# TF_STATE_BUCKET="vj-test-benvolate"
# TF_STATE_KEY="Cloudwatch/terraform.tfstate"
# AWS_REGION="us-east-2"
# TERRAFORM_DIR="$(dirname "$0")"
# INSTANCE_ID="i-0b7346b930b8a3ecd"  # Your EC2 instance ID

# echo ">>> Deploying Terraform for CloudWatch from: $TERRAFORM_DIR"

# # === Initialize Terraform with backend config ===
# echo ">>> Initializing Terraform..."
# terraform -chdir="$TERRAFORM_DIR" init \
#   -backend-config="bucket=$TF_STATE_BUCKET" \
#   -backend-config="key=$TF_STATE_KEY" \
#   -backend-config="region=$AWS_REGION" \
#   -backend-config="encrypt=true"

# # === Plan and apply ===
# echo ">>> Planning Terraform changes..."
# terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan

# echo ">>> Applying Terraform changes..."
# terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan

# # # # === Destroy resources ===
# # # terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve



# # === CloudWatch Debug Section ===
# echo ""
# echo "======================================"
# echo ">>> CloudWatch Agent Debug Section <<<"
# echo "======================================"

# # Get SSM document name from Terraform output
# # Correct way to get the SSM document name
# SSM_DOCUMENT=$(terraform -chdir="$TERRAFORM_DIR" output -raw ssm_document_name 2>/dev/null)
# if [ -z "$SSM_DOCUMENT" ]; then
#     echo "ERROR: SSM document name not found in Terraform output!"
#     exit 1
# fi
# echo "SSM Document: $SSM_DOCUMENT"

# # Correct way to send the command
# aws ssm send-command \
#   --document-name "$SSM_DOCUMENT" \
#   --targets "Key=instanceIds,Values=$INSTANCE_ID" \
#   --query 'Command.CommandId' \
#   --output text




# # Check if S3 config file exists
# echo ">>> Checking S3 configuration file..."
# if aws s3 ls "s3://$TF_STATE_BUCKET/Cloudwatch/cloudwatch-agent-config.json" >/dev/null 2>&1; then
#     echo "✓ S3 config file exists"
#     echo "Config file content preview:"
#     aws s3 cp "s3://$TF_STATE_BUCKET/Cloudwatch/cloudwatch-agent-config.json" - | head -10
# else
#     echo "✗ S3 config file missing!"
#     exit 1
# fi

# # Check SSM associations
# echo ">>> Checking SSM associations..."
# ASSOCIATIONS=$(aws ssm list-associations --query "Associations[?contains(Name, 'CloudWatchAgentConfig')].{Name:Name,AssociationId:AssociationId,Status:Status}" --output table)
# echo "$ASSOCIATIONS"

# # Execute SSM document to install/configure CloudWatch Agent
# echo ">>> Executing SSM document to configure CloudWatch Agent..."
# COMMAND_ID=$(aws ssm send-command \
#   --document-name "$SSM_DOCUMENT" \
#   --targets "Key=instanceIds,Values=$INSTANCE_ID" \
#   --query 'Command.CommandId' \
#   --output text)

# echo "Command ID: $COMMAND_ID"
# echo "Waiting for command execution..."

# # Wait for command completion (max 5 minutes)
# TIMEOUT=300
# ELAPSED=0
# while [ $ELAPSED -lt $TIMEOUT ]; do
#     STATUS=$(aws ssm get-command-invocation \
#         --command-id "$COMMAND_ID" \
#         --instance-id "$INSTANCE_ID" \
#         --query 'Status' \
#         --output text 2>/dev/null || echo "InProgress")
    
#     if [ "$STATUS" = "Success" ]; then
#         echo "✓ Command executed successfully!"
#         break
#     elif [ "$STATUS" = "Failed" ]; then
#         echo "✗ Command failed!"
#         aws ssm get-command-invocation \
#             --command-id "$COMMAND_ID" \
#             --instance-id "$INSTANCE_ID" \
#             --query 'StandardErrorContent' \
#             --output text
#         exit 1
#     fi
    
#     echo "Status: $STATUS (waiting...)"
#     sleep 10
#     ELAPSED=$((ELAPSED + 10))
# done

# if [ $ELAPSED -ge $TIMEOUT ]; then
#     echo "✗ Command timed out!"
#     exit 1
# fi

# # Show command output
# echo ">>> Command execution output:"
# aws ssm get-command-invocation \
#     --command-id "$COMMAND_ID" \
#     --instance-id "$INSTANCE_ID" \
#     --query 'StandardOutputContent' \
#     --output text




set -e

# === Configuration ===
TF_STATE_BUCKET="vj-test-benvolate"
TF_STATE_KEY="Cloudwatch/terraform.tfstate"
AWS_REGION="us-east-2"
TERRAFORM_DIR="$(dirname "$0")"
INSTANCE_ID="i-0b7346b930b8a3ecd"  # Your EC2 instance ID

echo ">>> Deploying Terraform for CloudWatch from: $TERRAFORM_DIR"

# === Initialize Terraform with backend config ===
terraform -chdir="$TERRAFORM_DIR" init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$TF_STATE_KEY" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="encrypt=true"

# === Plan and apply ===
terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan
# terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan


terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve



# # === CloudWatch Debug Section ===
# echo ""
# echo "======================================"
# echo ">>> CloudWatch Agent Debug Section <<<"
# echo "======================================"

# # Get SSM document name from Terraform output
# SSM_DOCUMENT=$(terraform -chdir="$TERRAFORM_DIR" output -raw ssm_document_name 2>/dev/null)
# if [ -z "$SSM_DOCUMENT" ]; then
#     echo "ERROR: SSM document name not found in Terraform output!"
#     exit 1
# fi
# echo "DEBUG: SSM_DOCUMENT is '$SSM_DOCUMENT'"

# aws ssm send-command \
#   --document-name "$SSM_DOCUMENT" \
#   --targets "Key=instanceIds,Values=$INSTANCE_ID" \
#   --query 'Command.CommandId' \
#   --output text

# # Check if S3 config file exists
# if aws s3 ls "s3://$TF_STATE_BUCKET/Cloudwatch/cloudwatch-agent-config.json" >/dev/null 2>&1; then
#     echo "✓ S3 config file exists"
#     echo "Config file content preview:"
#     aws s3 cp "s3://$TF_STATE_BUCKET/Cloudwatch/cloudwatch-agent-config.json" - | head -10
# else
#     echo "✗ S3 config file missing!"
#     exit 1
# fi

# # Check SSM associations
# ASSOCIATIONS=$(aws ssm list-associations --query "Associations[?contains(Name, 'CloudWatchAgentConfig')].{Name:Name,AssociationId:AssociationId,Status:Status}" --output table)
# echo "$ASSOCIATIONS"

# # Execute SSM document to install/configure CloudWatch Agent
# COMMAND_ID=$(aws ssm send-command \
#   --document-name "$SSM_DOCUMENT" \
#   --targets "Key=instanceIds,Values=$INSTANCE_ID" \
#   --query 'Command.CommandId' \
#   --output text)

# echo "Command ID: $COMMAND_ID"
# echo "Waiting for command execution..."

# # Wait for command completion (max 5 minutes)
# TIMEOUT=300
# ELAPSED=0
# while [ $ELAPSED -lt $TIMEOUT ]; do
#     STATUS=$(aws ssm get-command-invocation \
#         --command-id "$COMMAND_ID" \
#         --instance-id "$INSTANCE_ID" \
#         --query 'Status' \
#         --output text 2>/dev/null || echo "InProgress")
    
#     if [ "$STATUS" = "Success" ]; then
#         echo "✓ Command executed successfully!"
#         break
#     elif [ "$STATUS" = "Failed" ]; then
#         echo "✗ Command failed!"
#         aws ssm get-command-invocation \
#             --command-id "$COMMAND_ID" \
#             --instance-id "$INSTANCE_ID" \
#             --query 'StandardErrorContent' \
#             --output text
#         exit 1
#     fi
    
#     echo "Status: $STATUS (waiting...)"
#     sleep 10
#     ELAPSED=$((ELAPSED + 10))
# done

# if [ $ELAPSED -ge $TIMEOUT ]; then
#     echo "✗ Command timed out!"
#     exit 1
# fi

# # Show command output
# echo ">>> Command execution output:"
# aws ssm get-command-invocation \
#     --command-id "$COMMAND_ID" \
#     --instance-id "$INSTANCE_ID" \
#     --query 'StandardOutputContent' \
#     --output text
