#!/bin/bash
set -e

# === Configuration ===
TF_STATE_BUCKET="vj-test-benvolate"
TF_STATE_KEY="Cloudwatch/terraform.tfstate"
AWS_REGION="us-east-2"
TERRAFORM_DIR="$(dirname "$0")"

echo ">>> Deploying Terraform for EFS from: $TERRAFORM_DIR"

# === Initialize Terraform with backend config ===
terraform -chdir="$TERRAFORM_DIR" init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$TF_STATE_KEY" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="encrypt=true"

# === Plan and apply ===
terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan
# terraform -chdir="$TERRAFORM_DIR" apply -auto-approve tfplan

# # === Destroy resources ===
terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve
