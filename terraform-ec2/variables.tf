# variables.tf - Input variables for the EC2 root
#
# Only things that legitimately differ between plans are variables.
# Everything that is a fixed architectural decision (Ubuntu, ARM,
# gp3, IMDSv2) lives directly in the resource blocks instead --
# a variable nobody ever changes is just indirection.

variable "aws_region" {
  description = "AWS region for all resources in this root"
  type        = string
  default     = "eu-central-1" # Frankfurt, same as the Lightsail setup
}

variable "instance_type" {
  description = "EC2 instance type. ARM (Graviton) types only, the AMI lookup below is arm64."
  type        = string
  default     = "t4g.small" # 2 vCPU / 2 GiB -- decision 26.08.2026, resize is cheap later
}

variable "root_volume_size_gb" {
  description = "Size of the root EBS volume in GiB. Can be grown later without reinstalling, never shrunk."
  type        = number
  default     = 20 # blog currently uses 6.6 GiB, factor 3 headroom
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to reach SSH during bootstrap (your current public IP as x.x.x.x/32). After Tailscale is up this rule gets removed. No default on purpose: forces a conscious choice per plan."
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key material for the initial ubuntu user (contents of a .pub file, never the private key)"
  type        = string
}
