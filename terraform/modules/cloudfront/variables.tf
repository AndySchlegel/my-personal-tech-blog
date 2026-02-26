# variables.tf - CloudFront module input variables

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 assets bucket"
  type        = string
  # Must be the REGIONAL domain (not the global one) for OAC SigV4 signing.
  # Example: "blog-assets-his4irness23.s3.eu-central-1.amazonaws.com"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 assets bucket (for OAC policy)"
  type        = string
  # Used in the bucket policy to grant CloudFront read access.
}

variable "s3_bucket_id" {
  description = "ID of the S3 assets bucket (for OAC policy attachment)"
  type        = string
  # The bucket policy is attached to this bucket.
}

variable "domain_name" {
  description = "Blog domain name (e.g. blog.his4irness23.de)"
  type        = string
  # Used for: ACM certificate, CloudFront alias, Route 53 DNS record.
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS record creation"
  type        = string
  # The hosted zone for his4irness23.de. We create an A record
  # (blog.his4irness23.de -> CloudFront) in this zone.
}
