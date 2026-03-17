# backend.tf - Remote state configuration for Lightsail
#
# Stores Terraform state in S3 with DynamoDB locking, same as the EKS root.
# Uses a DIFFERENT state key (blog-lightsail/) so both roots can coexist
# without interfering with each other.
#
# Shared infrastructure:
#   - S3 bucket: blog-terraform-state-his4irness23 (same bucket, different key)
#   - DynamoDB:  blog-terraform-locks (same lock table)
#
# This means you can run 'terraform apply' in terraform/ and
# terraform-lightsail/ independently -- they track separate resources.

terraform {
  backend "s3" {
    bucket         = "blog-terraform-state-his4irness23"
    key            = "blog-lightsail/terraform.tfstate" # Separate from EKS state
    region         = "eu-central-1"
    dynamodb_table = "blog-terraform-locks" # Table for state locking
    encrypt        = true                   # Encrypt state at rest
  }
}
