# variables.tf - Lightsail module input variables
#
# Configures the Lightsail instance for permanent blog hosting (~$7/month).
# The instance runs Docker containers (nginx + backend + PostgreSQL).

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the Lightsail instance"
  type        = string
  default     = "eu-central-1a"
}

variable "bundle_id" {
  description = "Lightsail instance bundle (micro_3_0 = $7/month, 2 vCPU, 1GB RAM)"
  type        = string
  default     = "micro_3_0"
}

variable "blueprint_id" {
  description = "Lightsail instance OS blueprint"
  type        = string
  default     = "amazon_linux_2023"
}

variable "ssh_public_key" {
  description = "SSH public key for deployment access"
  type        = string
  default     = ""
  # If empty, the key pair resource is skipped.
  # Set via terraform.tfvars or GitHub Actions (from LIGHTSAIL_SSH_KEY).
}

variable "s3_bucket_name" {
  description = "S3 bucket name for DB backups"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for origin DNS record"
  type        = string
}

variable "domain_name" {
  description = "Base domain name (e.g. aws.his4irness23.de)"
  type        = string
}

variable "static_ip_address" {
  description = "Pre-existing Lightsail static IP address (not managed by Terraform -- import not supported)"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the Lightsail instance. Default: Tailscale subnet only."
  type        = list(string)
  default     = ["100.64.0.0/10"]
}
