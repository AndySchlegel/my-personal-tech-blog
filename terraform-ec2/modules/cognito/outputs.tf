# outputs.tf - Cognito module outputs
#
# The frontend and backend both need these values:
#   Frontend: redirects to Cognito login, stores client_id in config
#   Backend: validates JWT tokens against the user_pool_endpoint

output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.admin.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.admin.arn
}

output "user_pool_client_id" {
  description = "ID of the Cognito App Client (for frontend)"
  value       = aws_cognito_user_pool_client.admin.id
  # The frontend sends this with every auth request to identify itself
  # to Cognito. It's NOT a secret (safe to embed in frontend JS).
}

output "user_pool_domain" {
  description = "Cognito domain for hosted login UI"
  value       = aws_cognito_user_pool_domain.admin.domain
  # Full login URL: https://<domain>.auth.eu-central-1.amazoncognito.com/login
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint for JWT validation"
  value       = aws_cognito_user_pool.admin.endpoint
  # The backend uses this to download the JWKS (JSON Web Key Set)
  # and verify that JWT tokens were actually issued by this pool.
}
