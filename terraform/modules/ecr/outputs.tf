# outputs.tf - ECR module outputs
#
# The repo URLs are used in CI/CD and Kubernetes manifests:
#   docker push <url>:latest         (CI/CD pushes images here)
#   image: <url>:latest              (K8s Deployment spec pulls from here)
#
# Example URL: 123456789.dkr.ecr.eu-central-1.amazonaws.com/blog-frontend

output "frontend_repo_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_repo_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repo_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.arn
}

output "backend_repo_arn" {
  description = "ARN of the backend ECR repository"
  value       = aws_ecr_repository.backend.arn
}
