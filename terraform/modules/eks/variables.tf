# variables.tf - EKS module input variables

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
  # Worker nodes run in private subnets (no direct internet access).
  # They access the internet through the NAT Gateway.
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS cluster endpoint"
  type        = list(string)
  # Used for EKS-managed ENIs and the ALB (internet-facing).
}

variable "node_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  type        = string
  # Controls which traffic can reach the nodes (from ALB + within VPC).
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
  # Check AWS docs for supported versions before changing.
  # EKS supports N-3 versions (e.g., 1.28, 1.29, 1.30, 1.31).
}

variable "node_instance_types" {
  description = "Instance types for spot node group (multiple for flexibility)"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
  # Multiple types increase spot availability:
  # If t3.medium spots are unavailable, AWS can use t3a.medium instead.
  # Both have 2 vCPU and 4 GB RAM -- our containers don't care about CPU brand.
}

variable "node_desired" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2 # One per AZ
}

variable "node_min" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}
