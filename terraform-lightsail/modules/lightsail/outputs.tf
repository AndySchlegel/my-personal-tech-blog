# outputs.tf - Lightsail module outputs
#
# Provides the static IP (for CloudFront origin + DNS) and
# IAM credentials (for GitHub Secrets setup).

output "static_ip" {
  description = "Lightsail static IP address"
  value       = var.static_ip_address
}

output "origin_domain" {
  description = "DNS name for CloudFront origin (origin-lightsail.aws.his4irness23.de)"
  value       = aws_route53_record.origin.fqdn
}

output "instance_name" {
  description = "Lightsail instance name"
  value       = aws_lightsail_instance.blog.name
}


