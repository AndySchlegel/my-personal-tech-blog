# outputs.tf - GitHub OIDC module outputs
#
# These values are needed after 'terraform apply':
#   - role_arn: Set as the GitHub Secret AWS_ROLE_ARN
#   - role_name: Reference in aws-auth ConfigMap for kubectl access
#   - oidc_provider_arn: For reference/debugging

output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions (set as AWS_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the IAM role (for aws-auth ConfigMap mapping)"
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
