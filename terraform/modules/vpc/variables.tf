# variables.tf - VPC module input variables
#
# These variables are passed in from the root module (terraform/main.tf).
# They control the VPC's network layout, AZ distribution, and optional features.

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # /16 = 65,536 IPs, split into /24 subnets (256 IPs each)
}

variable "az_count" {
  description = "Number of availability zones (2 minimum for EKS)"
  type        = number
  default     = 2 # 2 AZs = good balance of availability vs. cost
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway for private subnet internet access (needed for EKS nodes)"
  type        = bool
  default     = false # ~$35/month -- only enable when deploying EKS (Wave 3)
}

variable "eks_cluster_name" {
  description = "EKS cluster name for subnet tagging"
  type        = string
  # The AWS Load Balancer Controller uses these tags to find the right subnets.
  # Without proper tags, the controller can't create ALBs.
}
