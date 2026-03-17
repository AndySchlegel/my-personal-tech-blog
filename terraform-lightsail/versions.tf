# versions.tf - Terraform and provider version constraints
#
# Pins Terraform CLI and provider versions for the Lightsail root module.
# This is independent from the EKS terraform/ root -- both share the same
# module sources but have separate state files and version constraints.
#
# ~> 5.0 means "any version >= 5.0 and < 6.0" (pessimistic constraint).
# Update periodically, but always test with 'terraform plan' after bumping.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider from HashiCorp registry
      version = "~> 5.0"
    }
  }
}
