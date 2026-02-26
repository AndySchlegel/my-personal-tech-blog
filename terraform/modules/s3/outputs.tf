# outputs.tf - S3 module outputs
#
# These are consumed by the CloudFront module to set up the CDN origin:
#   bucket_regional_domain_name -> CloudFront origin domain
#   bucket_arn                  -> S3 bucket policy for OAC access
#   bucket_id                   -> S3 bucket policy attachment

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.assets.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (for CloudFront OAC)"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
  # Use the REGIONAL domain name (not the global one) for CloudFront.
  # It's required for OAC to work correctly with SigV4 signing.
}
