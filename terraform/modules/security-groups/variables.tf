# variables.tf - Security Groups module input variables
#
# These come from the VPC module outputs, passed through the root module.

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created"
  type        = string
  # Security groups are VPC-scoped -- they can only be used by resources
  # in the same VPC.
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for internal communication rules"
  type        = string
  # Used in the EKS nodes SG to allow all traffic within the VPC
  # (node-to-node and node-to-control-plane communication).
}
