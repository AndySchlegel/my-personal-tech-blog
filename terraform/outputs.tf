# outputs.tf - Root module outputs
#
# These values are printed after 'terraform apply' and can be
# queried anytime with 'terraform output'.
#
# They provide the key endpoints and IDs needed to:
# - Configure kubectl for EKS access
# - Set up the CI/CD pipeline (ECR URLs for docker push)
# - Configure the backend's environment variables (RDS endpoint, Cognito IDs)
# - Verify the blog URL
#
# Example: terraform output rds_endpoint
# -> "blog-rds-dev.abc123.eu-central-1.rds.amazonaws.com:5432"

# --- VPC ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# --- ECR ---
# These URLs are used in the CI/CD pipeline:
#   docker tag blog-frontend:latest <ecr_frontend_url>:latest
#   docker push <ecr_frontend_url>:latest
output "ecr_frontend_url" {
  description = "ECR repository URL for frontend"
  value       = module.ecr.frontend_repo_url
}

output "ecr_backend_url" {
  description = "ECR repository URL for backend"
  value       = module.ecr.backend_repo_url
}

# --- RDS ---
# The backend uses this endpoint in its DATABASE_URL environment variable:
#   DATABASE_URL=postgresql://bloguser:<password>@<rds_endpoint>/techblog
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.rds_endpoint
}

# --- EKS ---
# Configure kubectl to connect to the cluster:
#   aws eks update-kubeconfig --name <cluster_name> --region eu-central-1
output "eks_cluster_name" {
  description = "EKS cluster name (for kubectl config)"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

# --- Cognito ---
# The frontend needs these values to redirect users to the login page
# and validate JWT tokens.
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID (for frontend)"
  value       = module.cognito.user_pool_client_id
}

# --- CloudFront ---
output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cloudfront.distribution_domain_name
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN for blog domain (for ALB HTTPS)"
  value       = module.cloudfront.acm_certificate_arn
}

# --- GitHub OIDC ---
# Set this as the AWS_ROLE_ARN secret in your GitHub repository settings.
# The deploy workflow uses this role for OIDC authentication.
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions (set as AWS_ROLE_ARN secret)"
  value       = module.github_oidc.role_arn
}

# --- Ingress placeholders ---
# These outputs provide the values needed to replace REPLACE_* placeholders
# in k8s/07-ingress.yaml. Set them as GitHub Secrets.
output "alb_sg_id" {
  description = "ALB security group ID (for ingress annotation)"
  value       = module.security_groups.alb_sg_id
}

output "public_subnet_ids" {
  description = "Comma-separated public subnet IDs (for ingress annotation)"
  value       = join(",", module.vpc.public_subnet_ids)
}

# The final blog URL -- this is what users type in their browser.
output "blog_url" {
  description = "Blog URL"
  value       = "https://${local.blog_domain}"
}
