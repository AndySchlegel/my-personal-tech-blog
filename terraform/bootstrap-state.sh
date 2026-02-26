#!/bin/bash
# bootstrap-state.sh - One-time setup for Terraform remote state
#
# Run this ONCE before the first 'terraform init'.
# Creates the S3 bucket and DynamoDB table needed for remote state.
#
# Why is this a shell script and not Terraform?
#   Chicken-and-egg problem: Terraform needs the S3 bucket to store its
#   state, but the bucket doesn't exist yet. We can't use Terraform to
#   create the bucket it depends on. So we use the AWS CLI for this
#   one-time bootstrap step.
#
# Prerequisites:
#   - AWS CLI installed and configured (aws configure)
#   - IAM permissions for S3 and DynamoDB
#
# Usage:
#   chmod +x bootstrap-state.sh
#   ./bootstrap-state.sh
#   cd terraform && terraform init

set -euo pipefail

BUCKET="blog-terraform-state-his4irness23"
TABLE="blog-terraform-locks"
REGION="eu-central-1"

echo "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

echo "Enabling versioning..."
# Versioning keeps previous state file versions for disaster recovery.
# If a bad 'terraform apply' corrupts the state, we can restore the previous version.
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "Enabling encryption..."
# Encrypt the state file at rest. The state may contain sensitive values
# like RDS passwords, so encryption is essential.
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

echo "Blocking public access..."
# State files should NEVER be publicly accessible.
# These settings block all public access, even if someone accidentally
# adds a public bucket policy later.
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Creating DynamoDB table for state locking..."
# PAY_PER_REQUEST: only pay for actual lock operations (pennies/month).
# The table has a single key: LockID (string), used by Terraform to
# identify which state file is locked.
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "Done! Now run: cd terraform && terraform init"
