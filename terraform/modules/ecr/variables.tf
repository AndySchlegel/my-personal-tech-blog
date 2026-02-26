# variables.tf - ECR module input variables
#
# ECR only needs the project name for repository naming.
# No VPC dependency -- ECR is a regional service, not VPC-bound.

variable "project_name" {
  description = "Project name used in repository naming"
  type        = string
  # Creates repos named: blog-frontend, blog-backend
}
