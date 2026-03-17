# main.tf - Lightsail root module wiring
#
# Standalone Terraform root for the permanent Lightsail deployment.
# Completely independent from the EKS terraform/ root -- separate state,
# separate lifecycle, no shared resources except the S3 state bucket.
#
# Architecture: Lightsail instance -> CloudFront (HTTPS + cache) -> Route 53
# S3 bucket stores blog assets (images, Polly audio), served via CloudFront OAC.
#
# Modules are local copies under ./modules/, independent from the EKS terraform/ root.
# The S3 module is simplified (Lightsail-only CORS). Lightsail and CloudFront are identical copies.

locals {
  # Construct the full Lightsail domain from subdomain + base domain.
  # "techblog" + "aws.his4irness23.de" -> "techblog.aws.his4irness23.de"
  lightsail_domain = "${var.lightsail_subdomain}.${var.domain_name}"
}

# Look up the existing Route 53 hosted zone for aws.his4irness23.de.
# This is a DATA source (read-only) -- it references the zone created
# when the domain was registered. It does NOT create a new one.
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# --- Cognito: Admin authentication ---
# Manages the admin user pool for the blog dashboard.
# Permanent resource -- admin users persist across deploy cycles.
# Both Lightsail and EKS reference this pool for admin authentication.
module "cognito" {
  source = "./modules/cognito"

  project_name     = var.project_name
  domain_name      = "blog.${var.domain_name}"  # EKS callback URL (kept for when EKS is spun up)
  lightsail_domain = local.lightsail_domain      # Lightsail callback URL
}

# --- S3: Asset storage (images, Polly audio) ---
# Bucket for blog assets, served through CloudFront via OAC.
# Only the Lightsail domain is passed for CORS (no EKS domain needed).
module "s3" {
  source = "./modules/s3"

  project_name     = var.project_name
  lightsail_domain = local.lightsail_domain
}

# --- Lightsail: Compute instance ---
# Single instance running Docker containers (nginx + backend + PostgreSQL).
# Creates static IP, SSH key pair, IAM user for AWS service access,
# firewall rules, and an origin DNS record for CloudFront.
module "lightsail" {
  source = "./modules/lightsail"

  project_name      = var.project_name
  environment       = var.environment
  ssh_public_key    = var.lightsail_ssh_public_key
  static_ip_address = var.lightsail_static_ip
  s3_bucket_name    = module.s3.bucket_id
  route53_zone_id   = data.aws_route53_zone.main.zone_id
  domain_name       = var.domain_name
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

# --- CloudFront: CDN with HTTPS ---
# Sits in front of Lightsail and S3, handling TLS termination and caching.
# Cache behaviors: /audio/* + /images/* -> S3, /api/* -> Lightsail (no cache),
# default -> Lightsail (5min cache).
# The providers block passes both default and us-east-1 providers because
# CloudFront ACM certificates must be created in us-east-1.
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name                   = var.project_name
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  s3_bucket_arn                  = module.s3.bucket_arn
  s3_bucket_id                   = module.s3.bucket_id
  domain_name                    = local.lightsail_domain
  route53_zone_id                = data.aws_route53_zone.main.zone_id
  lightsail_origin_domain        = module.lightsail.origin_domain
  origin_verify_secret           = var.origin_verify_secret

  # Pass both AWS providers to this module.
  # The module uses aws.us_east_1 for the ACM certificate.
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
