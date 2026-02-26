# outputs.tf - CloudFront module outputs

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
  # Needed for cache invalidation after deployments:
  #   aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
  # Example: "d1234abcdef8.cloudfront.net"
  # This is the CloudFront-assigned domain. Users access the blog via
  # blog.his4irness23.de (which is an alias pointing to this domain).
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.blog.arn
  # Can be reused by the ALB for HTTPS termination (added in Phase 5).
}
