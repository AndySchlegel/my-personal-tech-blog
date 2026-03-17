# outputs.tf - Lightsail module outputs
#
# Provides the static IP (for CloudFront origin + DNS) and
# IAM credentials (for GitHub Secrets setup).

output "static_ip" {
  description = "Lightsail static IP address"
  value       = aws_lightsail_static_ip.blog.ip_address
}

output "origin_domain" {
  description = "DNS name for CloudFront origin (origin-lightsail.aws.his4irness23.de)"
  value       = aws_route53_record.origin.fqdn
}

output "instance_name" {
  description = "Lightsail instance name"
  value       = aws_lightsail_instance.blog.name
}

output "backend_access_key_id" {
  description = "IAM access key ID for backend AWS services (set as GitHub Secret)"
  value       = aws_iam_access_key.lightsail_backend.id
  sensitive   = true
}

output "backend_secret_access_key" {
  description = "IAM secret access key for backend AWS services (set as GitHub Secret)"
  value       = aws_iam_access_key.lightsail_backend.secret
  sensitive   = true
}
