# providers.tf - AWS provider configuration for the EC2 root
#
# Region and default tags for every resource this root creates.
# The AWS credentials come from the CLI profile passed at runtime
# (AWS_PROFILE=homelab or -var, never hardcoded here) so the code
# stays portable and free of account-specific secrets.

provider "aws" {
  region = var.aws_region

  # Default tags are merged into every resource created by this root.
  # This is how we can always answer "what created this and why does
  # it exist" when looking at the AWS console or the bill.
  default_tags {
    tags = {
      Project     = "tech-blog"
      Environment = "production"
      ManagedBy   = "terraform-ec2" # which root owns the resource
    }
  }
}

# Second provider for us-east-1: CloudFront requires its ACM certificate
# to live in that region, everything else stays in Frankfurt.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "tech-blog"
      Environment = "production"
      ManagedBy   = "terraform-ec2"
    }
  }
}
