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
echo ">>> Initializing Terraform..."
terraform -chdir="$TERRAFORM_DIR" init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$TF_STATE_KEY" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="encrypt=true"

# === Plan and apply ===
echo ">>> Planning Terraform changes..."
terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan

echo ">>> Applying Terraform changes..."
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan

# === CloudWatch Debug Section ===
echo ""
echo "======================================"
echo ">>> CloudWatch Agent Debug Section <<<"
echo "======================================"

# Get SSM document name from Terraform output
echo ">>> Getting SSM document name..."
SSM_DOCUMENT=$(terraform -chdir="$TERRAFORM_DIR" output -raw ssm_document_name 2>/dev/null || echo "")
if [ -z "$SSM_DOCUMENT" ]; then
    echo "WARNING: Could not get SSM document name from Terraform output"
    SSM_DOCUMENT=$(aws ssm list-documents --filters "Key=Name,Values=CloudWatchAgentConfig-*" --query 'DocumentIdentifiers[0].Name' --output text)
fi
echo "SSM Document: $SSM_DOCUMENT"

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
ASSOCIATIONS=$(aws ssm list-associations --query "Associations[?contains(Name, 'CloudWatchAgentConfig')].{Name:Name,AssociationId:AssociationId,Status:Status}" --output table)
echo "$ASSOCIATIONS"

# Execute SSM document to install/configure CloudWatch Agent
echo ">>> Executing SSM document to configure CloudWatch Agent..."
COMMAND_ID=$(aws ssm send-command \
  --document-name "$SSM_DOCUMENT" \
  --targets "Key=instanceids,Values=$INSTANCE_ID" \
  --query 'Command.CommandId' \
  --output text)

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
        aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$INSTANCE_ID" \
            --query 'StandardErrorContent' \
            --output text
        exit 1
    fi
    
    echo "Status: $STATUS (waiting...)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "✗ Command timed out!"
    exit 1
fi

# Show command output
echo ">>> Command execution output:"
aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

# Wait a bit for agent to start
echo ">>> Waiting for CloudWatch Agent to start..."
sleep 15

# Check CloudWatch Agent status
echo ">>> Checking CloudWatch Agent status..."
AGENT_STATUS=$(aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=['sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status']" \
    --targets "Key=instanceids,Values=$INSTANCE_ID" \
    --query 'Command.CommandId' \
    --output text)

sleep 5
aws ssm get-command-invocation \
    --command-id "$AGENT_STATUS" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

# Check if config file was properly created
echo ">>> Verifying config file on EC2 instance..."
CONFIG_CHECK=$(aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=['echo \"=== Config file exists? ===\"; ls -la /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json 2>/dev/null && echo \"✓ Config file exists\" || echo \"✗ Config file missing\"; echo \"=== Config file content ===\"; sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json 2>/dev/null | head -20 || echo \"Cannot read config file\"']" \
    --targets "Key=instanceids,Values=$INSTANCE_ID" \
    --query 'Command.CommandId' \
    --output text)

sleep 5
aws ssm get-command-invocation \
    --command-id "$CONFIG_CHECK" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

# Check IAM permissions
echo ">>> Checking IAM permissions for CloudWatch..."
PERMISSION_CHECK=$(aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=['echo \"=== Testing CloudWatch permissions ===\"; aws logs describe-log-groups --max-items 1 >/dev/null 2>&1 && echo \"✓ CloudWatch Logs permissions OK\" || echo \"✗ CloudWatch Logs permissions FAILED\"; aws cloudwatch put-metric-data --namespace \"Test\" --metric-data MetricName=TestMetric,Value=1 >/dev/null 2>&1 && echo \"✓ CloudWatch Metrics permissions OK\" || echo \"✗ CloudWatch Metrics permissions FAILED\"']" \
    --targets "Key=instanceids,Values=$INSTANCE_ID" \
    --query 'Command.CommandId' \
    --output text)

sleep 5
aws ssm get-command-invocation \
    --command-id "$PERMISSION_CHECK" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

# Wait for log groups to be created (CloudWatch Agent needs time to start sending logs)
echo ">>> Waiting for log groups to be created (30 seconds)..."
sleep 30

# Check if log groups were created
echo ">>> Checking if log groups were created..."
EXPECTED_LOG_GROUPS=("system-logs" "security-logs" "nginx-access-logs" "nginx-error-logs" "node-app-logs")

echo "Current log groups:"
aws logs describe-log-groups --query 'logGroups[].logGroupName' --output table

echo ""
echo ">>> Checking expected log groups:"
for log_group in "${EXPECTED_LOG_GROUPS[@]}"; do
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$log_group"; then
        echo "✓ $log_group - EXISTS"
        
        # Check log streams
        STREAMS=$(aws logs describe-log-streams --log-group-name "$log_group" --query 'logStreams[].logStreamName' --output text 2>/dev/null || echo "")
        if [ -n "$STREAMS" ]; then
            echo "  └─ Log streams: $STREAMS"
        else
            echo "  └─ No log streams yet"
        fi
    else
        echo "✗ $log_group - MISSING"
    fi
done

# Check CloudWatch Agent logs for errors
echo ">>> Checking CloudWatch Agent logs for errors..."
AGENT_LOGS=$(aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=['echo \"=== Recent CloudWatch Agent logs ===\"; sudo tail -30 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log 2>/dev/null || echo \"Cannot read agent logs\"; echo \"=== Looking for errors ===\"; sudo grep -i error /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log 2>/dev/null | tail -10 || echo \"No errors found\"']" \
    --targets "Key=instanceids,Values=$INSTANCE_ID" \
    --query 'Command.CommandId' \
    --output text)

sleep 5
aws ssm get-command-invocation \
    --command-id "$AGENT_LOGS" \
    --instance-id "$INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text

# Final summary
echo ""
echo "=================================="
echo ">>> CloudWatch Deployment Summary"
echo "=================================="
echo "1. Terraform deployment: ✓ COMPLETED"
echo "2. CloudWatch Agent configuration: Check output above"
echo "3. Log groups creation: Check output above"
echo "4. Next steps:"
echo "   - Monitor log groups for incoming data"
echo "   - Check CloudWatch metrics in AWS Console"
echo "   - Verify log files are being tailed properly"
echo ""

# # === Destroy resources ===
# terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve