# providers.tf - AWS provider configuration for Lightsail deployment
#
# Two provider configurations are needed:
# 1. Default (eu-central-1 / Frankfurt): Lightsail instance, S3, Route 53
# 2. Alias "us_east_1": ACM certificates for CloudFront (must be in us-east-1)
#
# The ManagedBy tag is set to "terraform-lightsail" to distinguish resources
# created by this root from those created by the EKS terraform/ root.

# Primary provider: eu-central-1 (Frankfurt)
# All resources except CloudFront ACM certificates are created here.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name      # "blog" -- for cost tracking
      Environment = var.environment       # "dev" or "prod"
      ManagedBy   = "terraform-lightsail" # Distinguishes from EKS terraform root
    }
  }
}

# Secondary provider: us-east-1 (N. Virginia)
# Used ONLY by the CloudFront module for ACM certificate creation.
# CloudFront is a global service that reads certificates exclusively from us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform-lightsail"
    }
  }
}
