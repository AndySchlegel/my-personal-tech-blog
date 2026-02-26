# main.tf - CloudFront distribution with S3 origin
#
# CloudFront is AWS's CDN (Content Delivery Network).
# It caches our blog's static assets (images, CSS, JS) at edge locations
# around the world, so users get fast load times regardless of location.
#
# How it works:
#   1. User requests https://blog.his4irness23.de/images/photo.jpg
#   2. DNS (Route 53) points to CloudFront
#   3. CloudFront checks its edge cache
#   4. Cache HIT:  serve directly from edge (fast, ~10ms)
#      Cache MISS: fetch from S3 origin, cache it, then serve
#
# Security:
#   - HTTPS only (HTTP redirects to HTTPS)
#   - S3 origin uses OAC (Origin Access Control) -- CloudFront signs
#     every request to S3, so S3 can verify "this request came from
#     MY CloudFront distribution, not a random person."
#   - TLS 1.2 minimum (modern browsers only, no legacy support)
#
# ACM certificate for HTTPS must be in us-east-1 (CloudFront requirement).
# This is an AWS quirk: CloudFront is a global service, and it only reads
# certificates from the us-east-1 region. We use a provider alias for this.
#
# ALB origin for dynamic content (API routes) is added in Phase 5
# after EKS deployment. For now, only the S3 origin is configured.

# We need the us-east-1 provider for ACM certificates.
# This tells Terraform that this module requires a specific provider alias.
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# =============================================================================
# ACM CERTIFICATE (HTTPS)
# =============================================================================

# Request an SSL/TLS certificate for our blog domain.
# ACM (AWS Certificate Manager) provides free certificates.
# "DNS validation" means we prove domain ownership by creating a special
# DNS record -- Terraform does this automatically via Route 53 below.
resource "aws_acm_certificate" "blog" {
  provider          = aws.us_east_1 # Must be us-east-1 for CloudFront!
  domain_name       = var.domain_name
  validation_method = "DNS"

  # create_before_destroy: when renewing the certificate (every 13 months),
  # create the new cert first, then switch CloudFront to use it, then
  # delete the old cert. Prevents HTTPS downtime during renewal.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# Create DNS records that prove we own the domain.
# ACM gives us a CNAME record to create in Route 53. Once the record exists,
# ACM validates it and issues the certificate (usually takes ~5 minutes).
#
# for_each with domain_validation_options: ACM may require multiple
# validation records (one per domain/subdomain on the certificate).
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.blog.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true # Safe to overwrite if the record already exists from a previous apply
}

# Wait for ACM to validate the certificate.
# Terraform blocks here until ACM confirms the DNS records are correct
# and the certificate is issued. This can take up to 30 minutes.
resource "aws_acm_certificate_validation" "blog" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.blog.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# =============================================================================
# ORIGIN ACCESS CONTROL (OAC) for S3
# =============================================================================

# OAC tells CloudFront how to authenticate with S3.
# "signing_behavior = always" means CloudFront signs EVERY request to S3
# with SigV4 (AWS's request signing protocol). S3 then verifies:
# "Is this signature from the CloudFront distribution I trust?"
#
# This replaces the older OAI (Origin Access Identity) which had limitations
# with S3 features like SSE-KMS and bucket policies.
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# =============================================================================
# CLOUDFRONT DISTRIBUTION
# =============================================================================

resource "aws_cloudfront_distribution" "main" {
  #checkov:skip=CKV_AWS_68:WAF costs ~$5+/month minimum, not needed for a blog
  #checkov:skip=CKV2_AWS_47:No WAF deployed, Log4j AMR rule not applicable
  #checkov:skip=CKV_AWS_310:Origin failover needs 2nd origin, single S3 bucket sufficient
  #checkov:skip=CKV_AWS_86:Access logging needs dedicated S3 bucket, deferred to production
  #checkov:skip=CKV_AWS_374:Geo restriction not needed for public blog
  #checkov:skip=CKV2_AWS_32:Response headers policy deferred, security headers set via nginx
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name] # blog.his4irness23.de -> this distribution

  # PriceClass_100: only use edge locations in US, Canada, and Europe.
  # This is the cheapest option. PriceClass_200 adds Asia, PriceClass_All
  # includes South America, Australia, etc. For a personal blog with
  # mostly European traffic, PriceClass_100 is the right choice.
  price_class = "PriceClass_100"

  # S3 origin: where CloudFront fetches blog assets (images, static files).
  # The origin_id is an internal identifier used to reference this origin
  # in cache behaviors below.
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "s3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # Default cache behavior: how CloudFront handles requests.
  # All requests go to the S3 origin with aggressive caching.
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"] # Read-only (no POST/PUT/DELETE)
    cached_methods         = ["GET", "HEAD"]            # Cache GET and HEAD responses
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https" # HTTP -> HTTPS redirect

    # forwarded_values controls what CloudFront sends to the origin.
    # We don't forward query strings or cookies because S3 doesn't use them.
    # This maximizes cache hit ratio (same URL = same cached response).
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Cache TTLs (Time To Live):
    # min_ttl = 0:       respect Cache-Control headers from origin
    # default_ttl = 1d:  if origin doesn't set Cache-Control, cache for 1 day
    # max_ttl = 7d:      never cache longer than 7 days
    # compress = true:   serve gzip/brotli compressed responses (smaller files, faster loads)
    min_ttl     = 0
    default_ttl = 86400  # 1 day  (in seconds)
    max_ttl     = 604800 # 7 days (in seconds)
    compress    = true
  }

  # TLS certificate for HTTPS.
  # sni-only: use Server Name Indication (modern standard, free).
  # The alternative "vip" uses a dedicated IP ($600/month!) -- only needed
  # for very old clients that don't support SNI.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.blog.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021" # Only allow TLS 1.2+ (secure)
  }

  # No geographic restrictions -- the blog is accessible worldwide.
  # You could restrict to specific countries if needed (e.g. GDPR compliance).
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.project_name}-cdn-${var.domain_name}"
  }
}

# =============================================================================
# S3 BUCKET POLICY FOR CLOUDFRONT ACCESS
# =============================================================================

# This bucket policy tells S3: "Allow CloudFront to read my objects."
# It works together with the OAC above:
# 1. CloudFront signs requests with OAC
# 2. S3 checks this bucket policy to verify the request
# 3. The Condition block ensures ONLY our CloudFront distribution can access
#    the bucket -- not any other CloudFront distribution in any AWS account.
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"           # Read-only access
        Resource = "${var.s3_bucket_arn}/*" # All objects in the bucket
        Condition = {
          StringEquals = {
            # Only THIS specific CloudFront distribution can access the bucket
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# =============================================================================
# ROUTE 53 DNS RECORD
# =============================================================================

# Points blog.his4irness23.de to the CloudFront distribution.
# This is an "alias" record (AWS-specific) -- like a CNAME but works at
# the zone apex and doesn't cost extra for DNS queries.
# When someone visits blog.his4irness23.de, Route 53 resolves it to
# the nearest CloudFront edge location.
resource "aws_route53_record" "blog" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false # CloudFront handles its own health checks
  }
}
