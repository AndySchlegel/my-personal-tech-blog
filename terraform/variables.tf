# variables.tf - Root module variable declarations
#
# All configurable values for the entire infrastructure.
# Most variables have sensible defaults -- only db_password MUST be
# set in terraform.tfvars (because passwords should never be in code).
#
# To override defaults, either:
# 1. Set them in terraform.tfvars (recommended, see terraform.tfvars.example)
# 2. Pass them via CLI: terraform apply -var="environment=prod"
# 3. Set environment variables: TF_VAR_environment=prod

# --- General ---
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1" # Frankfurt -- closest to us, good latency for EU users
}

variable "project_name" {
  description = "Project name used in all resource naming"
  type        = string
  default     = "blog" # Prefix for all resources: blog-vpc-dev, blog-rds-dev, etc.
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev" # Used in resource names and tags for environment separation
}

# --- Domain ---
variable "domain_name" {
  description = "Base domain name (existing Route 53 hosted zone)"
  type        = string
  default     = "aws.his4irness23.de"
}

variable "blog_subdomain" {
  description = "Subdomain for the blog"
  type        = string
  default     = "blog" # Combined: blog.his4irness23.de
}

# --- VPC ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # 65,536 IP addresses -- more than enough
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway (needed for EKS, ~$35/month). Set to true in Wave 3."
  type        = bool
  default     = false # Off by default to save costs. Enable when deploying EKS.
}

# --- EKS ---
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.31" # Latest stable version at time of writing
}

variable "eks_node_instance_types" {
  description = "Instance types for spot node group"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"] # 2 types for better spot availability
}

variable "eks_node_desired" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2 # One per AZ for high availability
}

variable "eks_node_min" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1 # Allow scaling down to 1 during low traffic
}

variable "eks_node_max" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 3 # Allow scaling up for traffic spikes
}

# --- RDS ---
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # 2 vCPU, 1 GB RAM -- sufficient for a blog (~$13/month)
}

variable "rds_db_name" {
  description = "Database name (matches docker-compose)"
  type        = string
  default     = "techblog" # Must match POSTGRES_DB in docker-compose.yml
}

variable "rds_db_username" {
  description = "Database master username (matches docker-compose)"
  type        = string
  default     = "bloguser" # Must match POSTGRES_USER in docker-compose.yml
}

variable "db_password" {
  description = "Database master password. Set in terraform.tfvars, NEVER commit."
  type        = string
  sensitive   = true # Terraform will hide this value in plan/apply output
  # No default! Forces you to set this in terraform.tfvars.
  # Use a strong password: at least 16 chars, mix of letters/numbers/symbols.
}

# --- CI/CD ---
variable "github_repository" {
  description = "GitHub repository for OIDC trust (format: owner/repo)"
  type        = string
  default     = "AndySchlegel/my-personal-tech-blog"
}
