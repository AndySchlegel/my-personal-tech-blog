# outputs.tf - Lightsail root module outputs
#
# Key values printed after 'terraform apply' and queryable with 'terraform output'.
# These provide the endpoints and credentials needed for:
# - SSH access to the Lightsail instance
# - CI/CD pipeline configuration (GitHub Secrets)
# - CloudFront cache invalidation after deployments
# - Verifying the blog URL

# --- Lightsail ---
output "lightsail_static_ip" {
  description = "Lightsail instance public IP (for SSH access)"
  value       = module.lightsail.static_ip
}

output "lightsail_instance_name" {
  description = "Lightsail instance name"
  value       = module.lightsail.instance_name
}

# IAM credentials for the backend to access AWS services (Translate, Polly, Comprehend, S3).
# Set these as GitHub Secrets: LIGHTSAIL_AWS_ACCESS_KEY_ID, LIGHTSAIL_AWS_SECRET_ACCESS_KEY


# --- CloudFront ---


# --- S3 ---

# --- Cognito ---


# --- URL ---
# The final blog URL -- what users type in their browser.
output "lightsail_url" {
  description = "Lightsail blog URL"
  value       = "https://${local.lightsail_domain}"
}
