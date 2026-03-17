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
output "lightsail_backend_access_key_id" {
  description = "IAM access key ID for Lightsail backend (set as LIGHTSAIL_AWS_ACCESS_KEY_ID)"
  value       = module.lightsail.backend_access_key_id
  sensitive   = true
}

output "lightsail_backend_secret_access_key" {
  description = "IAM secret key for Lightsail backend (set as LIGHTSAIL_AWS_SECRET_ACCESS_KEY)"
  value       = module.lightsail.backend_secret_access_key
  sensitive   = true
}

# --- CloudFront ---
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (e.g. d1234abcdef8.cloudfront.net)"
  value       = module.cloudfront.distribution_domain_name
}

# --- S3 ---
output "s3_bucket_name" {
  description = "S3 bucket name for assets (audio, images)"
  value       = module.s3.bucket_id
}

# --- URL ---
# The final blog URL -- what users type in their browser.
output "lightsail_url" {
  description = "Lightsail blog URL"
  value       = "https://${local.lightsail_domain}"
}
