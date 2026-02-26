# versions.tf - Terraform and provider version constraints
#
# This file pins the Terraform CLI version and provider versions
# to prevent unexpected breaking changes when updating.
#
# ~> 5.0 means "any version >= 5.0 and < 6.0" (pessimistic constraint).
# This allows minor updates (5.1, 5.2, etc.) but blocks major version
# bumps that might have breaking changes.
#
# Update these periodically (check the Terraform and AWS provider
# changelogs), but always test with 'terraform plan' after bumping.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider from HashiCorp registry
      version = "~> 5.0"
    }
  }
}
