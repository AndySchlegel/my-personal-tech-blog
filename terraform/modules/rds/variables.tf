# variables.tf - RDS module input variables

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
  # Must be in at least 2 AZs (AWS requirement for DB subnet groups).
  # These come from the VPC module's private_subnet_ids output.
}

variable "security_group_id" {
  description = "Security group ID for RDS access"
  type        = string
  # The RDS SG only allows inbound traffic from EKS nodes on port 5432.
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # 2 vCPU, 1 GB RAM, ~$13/month
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "techblog" # Must match POSTGRES_DB in docker-compose.yml
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "bloguser" # Must match POSTGRES_USER in docker-compose.yml
}

variable "db_password" {
  description = "Master password for the database (never commit this)"
  type        = string
  sensitive   = true # Hidden in terraform plan/apply output
  # Set this in terraform.tfvars (which is .gitignored).
  # Use a strong password with 16+ chars, mixed characters.
}
