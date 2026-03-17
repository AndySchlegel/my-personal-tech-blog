# Terraform State Migration: EKS -> Lightsail Separation

This document describes how to migrate Lightsail, CloudFront, and S3 resources
from the shared `terraform/` state to the independent `terraform-lightsail/` state.

## Prerequisites

- AWS CLI configured with admin access
- Terraform 1.9.0 installed
- No other terraform operations running (check DynamoDB locks)

## Step 1: Note resource identifiers

```bash
cd terraform/

# Get CloudFront distribution ID
terraform output cloudfront_distribution_id

# Get ACM certificate ARN (from terraform state)
terraform state show module.cloudfront.aws_acm_certificate.blog | grep arn

# Get CloudFront OAC ID
terraform state show module.cloudfront.aws_cloudfront_origin_access_control.s3 | grep '"id"'

# Get Route53 zone ID
terraform state show 'data.aws_route53_zone.main' | grep zone_id

# List all Lightsail resources
terraform state list | grep lightsail

# List all CloudFront resources
terraform state list | grep cloudfront

# List all S3 resources
terraform state list | grep 'module.s3'
```

## Step 2: Remove resources from OLD state

This ONLY removes tracking -- the actual AWS resources stay running.

```bash
cd terraform/

terraform state rm module.lightsail
terraform state rm module.cloudfront
terraform state rm module.s3
```

## Step 3: Initialize new state

```bash
cd terraform-lightsail/
terraform init
```

## Step 4: Import resources into NEW state

Replace placeholders with values from Step 1.

### S3 resources
```bash
terraform import module.s3.aws_s3_bucket.assets blog-assets-his4irness23
terraform import module.s3.aws_s3_bucket_versioning.assets blog-assets-his4irness23
terraform import module.s3.aws_s3_bucket_server_side_encryption_configuration.assets blog-assets-his4irness23
terraform import module.s3.aws_s3_bucket_public_access_block.assets blog-assets-his4irness23
terraform import module.s3.aws_s3_bucket_cors_configuration.assets blog-assets-his4irness23
terraform import module.s3.aws_s3_bucket_lifecycle_configuration.assets blog-assets-his4irness23
```

### Lightsail resources
```bash
terraform import module.lightsail.aws_lightsail_instance.blog blog-lightsail-dev
terraform import module.lightsail.aws_lightsail_static_ip.blog blog-lightsail-ip
terraform import module.lightsail.aws_lightsail_static_ip_attachment.blog blog-lightsail-dev,blog-lightsail-ip
terraform import module.lightsail.aws_lightsail_instance_public_ports.blog blog-lightsail-dev
terraform import module.lightsail.aws_lightsail_key_pair.deploy[0] blog-lightsail-key
terraform import module.lightsail.aws_iam_user.lightsail_backend blog-lightsail-backend
terraform import module.lightsail.aws_iam_user_policy.lightsail_backend blog-lightsail-backend:blog-lightsail-backend-policy
terraform import 'module.lightsail.aws_route53_record.origin' '<ZONE_ID>_origin-lightsail.aws.his4irness23.de_A'
```

### CloudFront resources
```bash
terraform import module.cloudfront.aws_acm_certificate.blog <ACM_CERT_ARN>
terraform import module.cloudfront.aws_acm_certificate_validation.blog <ACM_CERT_ARN>
terraform import module.cloudfront.aws_cloudfront_origin_access_control.s3 <OAC_ID>
terraform import module.cloudfront.aws_cloudfront_distribution.main <DISTRIBUTION_ID>
terraform import 'module.cloudfront.aws_route53_record.blog' '<ZONE_ID>_techblog.aws.his4irness23.de_A'
terraform import 'module.cloudfront.aws_route53_record.cert_validation["techblog.aws.his4irness23.de"]' '<ZONE_ID>_<CNAME_NAME>_CNAME'
terraform import module.cloudfront.aws_s3_bucket_policy.cloudfront_access blog-assets-his4irness23
```

## Step 5: Plan and verify

```bash
terraform plan -var="origin_verify_secret=934f06a770e8a7f13c60046c00391fdceb5a476c52f3a46fbbff189261c1db61"
```

Expected: minimal changes (CORS update removing EKS domain, new IAM access key, origin verify header on CloudFront).

## Step 6: Apply

```bash
terraform apply -var="origin_verify_secret=934f06a770e8a7f13c60046c00391fdceb5a476c52f3a46fbbff189261c1db61"
```

## Step 7: Update GitHub Secrets

After apply, get new IAM credentials from outputs:
```bash
terraform output lightsail_backend_access_key_id
terraform output lightsail_backend_secret_access_key
```

Update in GitHub:
- `LIGHTSAIL_AWS_ACCESS_KEY_ID`
- `LIGHTSAIL_AWS_SECRET_ACCESS_KEY`

## Step 8: Redeploy

```bash
gh workflow run deploy-lightsail.yml --ref develop
```

## Step 9: Clean up old terraform/ root

Remove Lightsail/CloudFront module blocks and variables from `terraform/main.tf`.

## IMPORTANT: IAM Access Key

The `aws_iam_access_key` resource CANNOT be imported (AWS never exposes the
secret key after creation). Terraform will create a NEW access key on first apply.
The old key remains valid until manually deleted. Update GitHub Secrets with the
new key values from terraform output.
