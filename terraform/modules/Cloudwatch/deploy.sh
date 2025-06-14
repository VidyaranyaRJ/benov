#!/bin/bash
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
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan


# terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve


# === CloudWatch Debug Section ===
echo ""
echo "======================================"
echo ">>> CloudWatch Agent Debug Section <<<"
echo "======================================"

# Get SSM document name from Terraform output with better error handling
echo ">>> Getting SSM document name from Terraform output..."
SSM_DOCUMENT_RAW=$(terraform -chdir="$TERRAFORM_DIR" output ssm_document_name 2>&1)
echo "DEBUG: Raw Terraform output: '$SSM_DOCUMENT_RAW'"

# Extract just the document name (remove quotes and any extra content)
SSM_DOCUMENT=$(echo "$SSM_DOCUMENT_RAW" | grep -E '^"?CloudWatchAgentConfig-[a-f0-9]+"?$' | tr -d '"' | head -1)

if [ -z "$SSM_DOCUMENT" ]; then
    echo "ERROR: Could not extract SSM document name from Terraform output!"
    echo "Raw output was: $SSM_DOCUMENT_RAW"
    
    # Alternative: try to get it from terraform state directly
    echo ">>> Trying alternative method to get SSM document name..."
    SSM_DOCUMENT=$(terraform -chdir="$TERRAFORM_DIR" state show 'aws_ssm_document.benevolate_cloudwatch_agent_document' 2>/dev/null | grep -E '^\s*name\s*=' | sed 's/.*= "//' | sed 's/"//')
    
    if [ -z "$SSM_DOCUMENT" ]; then
        echo "ERROR: SSM document name not found using alternative method either!"
        exit 1
    fi
fi

echo "DEBUG: Extracted SSM_DOCUMENT is '$SSM_DOCUMENT'"

# Validate the document name format
if [[ ! "$SSM_DOCUMENT" =~ ^CloudWatchAgentConfig-[a-f0-9]+$ ]]; then
    echo "ERROR: SSM document name format is invalid: '$SSM_DOCUMENT'"
    exit 1
fi

# Check if S3 config file exists
echo ">>> Checking S3 configuration file..."
if aws s3 ls "s3://$TF_STATE_BUCKET/Cloudwatch/cloudwatch-agent-config.json" >/dev/null 2>&1; then
    echo "✓ S3 config file exists"
    echo "Config file content preview:"
    aws s3 cp "s3://$TF_STATE_BUCKET/Cloudwatch/cloudwatch-agent-config.json" - | head -10
else
    echo "✗ S3 config file missing!"
    exit 1
fi

# Check SSM associations
echo ">>> Checking SSM associations..."
ASSOCIATIONS=$(aws ssm list-associations --query "Associations[?contains(Name, 'CloudWatchAgentConfig')].{Name:Name,AssociationId:AssociationId,Status:Status}" --output table 2>/dev/null || echo "No associations found")
echo "$ASSOCIATIONS"

# Verify the SSM document exists
echo ">>> Verifying SSM document exists..."
if aws ssm describe-document --name "$SSM_DOCUMENT" >/dev/null 2>&1; then
    echo "✓ SSM document '$SSM_DOCUMENT' exists"
else
    echo "✗ SSM document '$SSM_DOCUMENT' not found!"
    exit 1
fi

# Execute SSM document to install/configure CloudWatch Agent
echo ">>> Executing SSM document '$SSM_DOCUMENT' to configure CloudWatch Agent..."
COMMAND_ID=$(aws ssm send-command \
  --document-name "$SSM_DOCUMENT" \
  --targets "Key=instanceIds,Values=$INSTANCE_ID" \
  --query 'Command.CommandId' \
  --output text)

if [ -z "$COMMAND_ID" ] || [ "$COMMAND_ID" = "None" ]; then
    echo "ERROR: Failed to send SSM command!"
    exit 1
fi

echo "Command ID: $COMMAND_ID"
echo "Waiting for command execution..."

# Wait for command completion (max 5 minutes)
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --query 'Status' \
        --output text 2>/dev/null || echo "InProgress")
    
    if [ "$STATUS" = "Success" ]; then
        echo "✓ Command executed successfully!"
        break
    elif [ "$STATUS" = "Failed" ]; then
        echo "✗ Command failed!"
        echo ">>> Error output:"
        aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query 'StandardErrorContent' \
            --output text
        echo ">>> Standard output:"
        aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query 'StandardOutputContent' \
            --output text
        exit 1
    elif [ "$STATUS" = "Cancelled" ]; then
        echo "✗ Command was cancelled!"
        exit 1
    fi
    
    echo "Status: $STATUS (waiting...)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "✗ Command timed out after $TIMEOUT seconds!"
    echo ">>> Current status:"
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --query '{Status:Status,StatusDetails:StatusDetails}' \
        --output table 2>/dev/null || echo "Could not get status"
    exit 1
fi

# Show command output
echo ">>> Command execution output:"
aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

echo ""
echo "======================================"
echo ">>> CloudWatch Agent Deployment Complete! <<<"
echo "======================================"
