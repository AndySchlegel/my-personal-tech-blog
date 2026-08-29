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
  s3_bucket_name    = "blog-assets-his4irness23" # bucket now lives in terraform-ec2; hardcoded until this root is destroyed
  route53_zone_id   = data.aws_route53_zone.main.zone_id
  domain_name       = var.domain_name
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

