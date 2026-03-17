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

# --- Cognito (managed by terraform-lightsail/, referenced via data source) ---
# The Cognito user pool is permanently managed by the Lightsail root.
# These outputs use data source lookups so deploy.yml can still read them.
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (from data source)"
  value       = tolist(data.aws_cognito_user_pools.admin.ids)[0]
}

# Cognito client ID and domain must be looked up via AWS CLI since the
# data source aws_cognito_user_pools only returns pool IDs, not client details.
# The deploy.yml workflow reads these directly from GitHub Secrets instead.
output "cognito_client_id" {
  description = "Cognito client ID (read from GitHub Secret COGNITO_CLIENT_ID in deploy.yml)"
  value       = "see-github-secrets"
}

output "cognito_domain" {
  description = "Cognito domain prefix for Hosted UI"
  value       = "${var.project_name}-admin-auth"
}

# --- ALB Certificate ---
output "alb_acm_certificate_arn" {
  description = "ACM certificate ARN for ALB (eu-central-1)"
  value       = var.create_alb_cert ? aws_acm_certificate_validation.alb[0].certificate_arn : ""
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

# --- EKS ALB Controller ---
# The IRSA role ARN that the AWS Load Balancer Controller pod uses
# to create and manage ALBs. Passed to Helm during controller install.
output "alb_controller_role_arn" {
  description = "ALB controller IRSA role ARN (for Helm install)"
  value       = module.eks.alb_controller_role_arn
}

# --- S3 (managed by terraform-lightsail/, referenced via data source) ---
output "s3_bucket_name" {
  description = "S3 bucket name for assets (from data source)"
  value       = data.aws_s3_bucket.assets.id
}

# --- Backend IRSA Role ---
# The IRSA role ARN for the blog-backend pod. Gives Comprehend permissions.
# Used in the ServiceAccount annotation during deploy.
output "backend_role_arn" {
  description = "Backend IRSA role ARN (Comprehend permissions)"
  value       = module.eks.backend_role_arn
}

# --- Grafana IRSA Role ---
# The IRSA role ARN for the Grafana pod. Gives CloudWatch read access
# for the AWS ML Services dashboard (Translate/Polly/Comprehend metrics).
output "grafana_role_arn" {
  description = "Grafana IRSA role ARN (CloudWatch read access)"
  value       = module.eks.grafana_role_arn
}

# --- Route 53 ---
# Zone ID needed by the deploy pipeline to update DNS (point to ALB).
output "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS updates"
  value       = data.aws_route53_zone.main.zone_id
}

# Blog domain without protocol -- used by deploy pipeline for Route 53 record name.
output "blog_domain" {
  description = "Blog domain name (e.g. blog.aws.his4irness23.de)"
  value       = local.blog_domain
}

# The final blog URL -- this is what users type in their browser.
output "blog_url" {
  description = "Blog URL"
  value       = "https://${local.blog_domain}"
}

# NOTE: Lightsail, CloudFront, and S3 outputs have been moved to terraform-lightsail/outputs.tf.
