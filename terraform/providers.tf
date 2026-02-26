# providers.tf - AWS provider configuration
#
# Providers are Terraform's plugins for interacting with cloud APIs.
# The AWS provider translates our Terraform resources into AWS API calls.
#
# We need TWO provider configurations:
# 1. Default (eu-central-1 / Frankfurt): where all our resources live
# 2. Alias "us_east_1": ONLY for ACM certificates used by CloudFront
#
# Why us-east-1 for CloudFront certs?
#   CloudFront is a global service that reads certificates exclusively
#   from us-east-1. This is an AWS design decision -- all CloudFront
#   users worldwide must create their ACM certs in us-east-1.
#
# default_tags: automatically applied to EVERY resource created by this
# provider. Saves us from repeating Project/Environment/ManagedBy tags
# in every resource block. These tags help with cost tracking and
# identifying which resources belong to this project.

# Primary provider: eu-central-1 (Frankfurt)
# All resources except ACM certificates are created here.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name # "blog" -- for cost tracking
      Environment = var.environment  # "dev" or "prod"
      ManagedBy   = "terraform"      # Distinguishes from manually created resources
    }
  }
}

# Secondary provider: us-east-1 (N. Virginia)
# Used ONLY by the CloudFront module for ACM certificate creation.
# The CloudFront module references this via: provider = aws.us_east_1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
