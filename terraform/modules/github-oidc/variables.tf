# variables.tf - GitHub OIDC module inputs
#
# These values are passed from the root module (terraform/main.tf).
# Most are derived from other module outputs or root variables.

variable "project_name" {
  description = "Project name used in resource naming (e.g. 'blog' -> 'blog-github-actions-role')"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository for OIDC trust policy (format: owner/repo)"
  type        = string
  # Example: "AndySchlegel/my-personal-tech-blog"
  # The trust policy will only allow this specific repo to assume the role.
}

variable "ecr_repo_arns" {
  description = "List of ECR repository ARNs that GitHub Actions can push/pull images to"
  type        = list(string)
  # Example: ["arn:aws:ecr:eu-central-1:123456789:repository/blog-frontend",
  #           "arn:aws:ecr:eu-central-1:123456789:repository/blog-backend"]
}

variable "eks_cluster_name" {
  description = "EKS cluster name for DescribeCluster permission (e.g. 'blog-eks-dev')"
  type        = string
}

variable "aws_region" {
  description = "AWS region (needed to construct EKS cluster ARN)"
  type        = string
}
