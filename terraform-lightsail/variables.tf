# variables.tf - Lightsail root module variable declarations
#
# Simplified variable set for standalone Lightsail deployment.
# No EKS, RDS, VPC, or other EKS-specific variables needed.
#
# To override defaults, either:
# 1. Set them in terraform.tfvars (recommended)
# 2. Pass them via CLI: terraform apply -var="environment=prod"
# 3. Set environment variables: TF_VAR_environment=prod

# --- General ---
variable "project_name" {
  description = "Project name used in all resource naming"
  type        = string
  default     = "blog" # Prefix for all resources: blog-lightsail-dev, etc.
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev" # Used in resource names and tags
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1" # Frankfurt -- closest, good latency for EU users
}

# --- Domain ---
variable "domain_name" {
  description = "Base domain name (existing Route 53 hosted zone)"
  type        = string
  default     = "aws.his4irness23.de"
}

variable "lightsail_subdomain" {
  description = "Subdomain for Lightsail blog (combined with domain_name)"
  type        = string
  default     = "techblog" # Combined: techblog.aws.his4irness23.de
}

# --- Lightsail ---
variable "lightsail_static_ip" {
  description = "Pre-existing Lightsail static IP address (not Terraform-managed, import not supported)"
  type        = string
  default     = "63.183.111.225"
}

variable "lightsail_ssh_public_key" {
  description = "SSH public key for Lightsail deployment access. Set via tfvars or CI/CD."
  type        = string
  default     = "" # If empty, no key pair is created
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the Lightsail instance. Default: Tailscale subnet only."
  type        = list(string)
  default     = ["100.64.0.0/10"] # Tailscale CGNAT range
}

# --- CloudFront ---
variable "origin_verify_secret" {
  description = "Secret header sent by CloudFront to verify requests come from CDN, not direct IP access. Set via TF_VAR_origin_verify_secret or terraform.tfvars."
  type        = string
  sensitive   = true
  # No default! Must be set explicitly.
}
