# backend.tf - Remote state configuration for the EC2 root
#
# Stores Terraform state in S3 with DynamoDB locking, same pattern as the
# EKS and Lightsail roots. Uses its OWN state key (blog-ec2/) so all three
# roots coexist without touching each other's resources.
#
# Shared infrastructure (already exists, created by the EKS root):
#   - S3 bucket: blog-terraform-state-his4irness23 (same bucket, new key)
#   - DynamoDB:  blog-terraform-locks (same lock table)

terraform {
  backend "s3" {
    bucket         = "blog-terraform-state-his4irness23"
    key            = "blog-ec2/terraform.tfstate" # Separate from EKS and Lightsail state
    region         = "eu-central-1"
    dynamodb_table = "blog-terraform-locks" # Table for state locking
    encrypt        = true                   # Encrypt state at rest
  }
}
