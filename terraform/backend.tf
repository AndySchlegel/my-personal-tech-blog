# backend.tf - Remote state configuration
#
# By default, Terraform stores its state (a JSON file tracking all
# created resources) locally in terraform.tfstate. This is problematic:
# - If the file is lost, Terraform "forgets" what it created
# - Multiple people can't safely run Terraform at the same time
# - The state file may contain secrets (RDS password, etc.)
#
# Solution: store state in S3 with DynamoDB locking.
#
# S3 bucket: stores the state file with versioning and encryption.
#   - Versioning lets us roll back to a previous state if something goes wrong.
#   - Encryption (AES256) protects sensitive values in the state file.
#
# DynamoDB table: provides state locking.
#   - When you run 'terraform apply', it creates a lock in DynamoDB.
#   - If someone else tries to run 'terraform apply' at the same time,
#     they get an error: "Error locking state: ConflictException"
#   - This prevents two people from modifying infrastructure simultaneously.
#
# IMPORTANT: The S3 bucket and DynamoDB table must be created BEFORE
# running 'terraform init'. This is the "chicken-and-egg" problem --
# Terraform can't manage the bucket it stores its state in.
# See bootstrap-state.sh for the one-time setup commands.

terraform {
  backend "s3" {
    bucket         = "blog-terraform-state-his4irness23"
    key            = "blog/terraform.tfstate" # Path within the bucket
    region         = "eu-central-1"
    dynamodb_table = "blog-terraform-locks" # Table for state locking
    encrypt        = true                   # Encrypt state at rest
  }
}
