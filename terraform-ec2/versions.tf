# versions.tf - Terraform and provider version constraints
#
# Pins Terraform CLI and provider versions for the EC2 root module.
# Third root in this repo, next to terraform/ (EKS) and terraform-lightsail/.
# All roots share the state bucket but use separate state keys, so they
# can be planned and applied independently.
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
