# outputs.tf - EKS module outputs
#
# These values are needed for:
#   kubectl configuration, CI/CD pipeline, and Kubernetes resource deployment.

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
  # Used with: aws eks update-kubeconfig --name <cluster_name>
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS API server"
  value       = aws_eks_cluster.main.endpoint
  # The URL that kubectl uses to communicate with the cluster.
  # Example: "https://ABC123.gr7.eu-central-1.eks.amazonaws.com"
}

output "cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  # The kubeconfig needs this certificate to verify the cluster's identity
  # (TLS server verification). Prevents man-in-the-middle attacks.
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
  # Used when creating additional IRSA roles (e.g., for S3 access, Comprehend).
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.node.arn
  # Useful for adding additional policies to nodes later.
}

output "alb_controller_role_arn" {
  description = "ARN of the ALB controller IRSA role"
  value       = aws_iam_role.alb_controller.arn
  # Used in the Kubernetes ServiceAccount annotation:
  #   eks.amazonaws.com/role-arn: <this ARN>
  # This tells EKS to inject AWS credentials for this role into the pod.
}
