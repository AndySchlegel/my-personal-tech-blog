# main.tf - CloudFront distribution with S3 + Lightsail origins
#
# CloudFront is AWS's CDN (Content Delivery Network).
# It serves as the central entry point for the blog:
#   - HTTPS termination (no certbot needed on Lightsail)
#   - S3 origin for static assets (audio files, images)
#   - Lightsail origin for the app (HTML, CSS, JS, API)
#
# Traffic routing (ordered by priority):
#   /audio/*   -> S3 origin (OAC), TTL 7 days (immutable audio files)
#   /images/*  -> S3 origin (OAC), TTL 7 days (immutable images)
#   /api/*     -> Lightsail origin, TTL 0 (no cache, forward all)
#   *.css/js   -> Lightsail origin, TTL 1 day (static assets)
#   Default    -> Lightsail origin, TTL 5 min (HTML pages)
#
# ACM certificate for HTTPS must be in us-east-1 (CloudFront requirement).
# This is an AWS quirk: CloudFront is a global service, and it only reads
# certificates from the us-east-1 region. We use a provider alias for this.

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
  #checkov:skip=CKV_AWS_310:Origin failover not needed, Lightsail is the single app origin
  #checkov:skip=CKV_AWS_86:Access logging needs dedicated S3 bucket, deferred to production
  #checkov:skip=CKV_AWS_374:Geo restriction not needed for public blog
  #checkov:skip=CKV2_AWS_32:Response headers policy deferred, security headers set via nginx
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name] # techblog.aws.his4irness23.de -> this distribution

  # PriceClass_100: only use edge locations in US, Canada, and Europe.
  # This is the cheapest option. For a personal blog with mostly European
  # traffic, PriceClass_100 is the right choice.
  price_class = "PriceClass_100"

  # --- S3 origin: audio files and images ---
  # Served via OAC (signed requests). Used for /audio/* and /images/* paths.
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "s3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # --- Lightsail origin: the blog application ---
  # HTTP only (port 80). CloudFront handles HTTPS termination.
  # Used for HTML pages, API requests, and static frontend assets.
  origin {
    domain_name = var.lightsail_origin_domain
    origin_id   = "lightsail-app"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # Lightsail serves HTTP, CloudFront adds HTTPS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # =========================================================================
  # ORDERED CACHE BEHAVIORS (evaluated in order, first match wins)
  # =========================================================================

  # 1. /audio/* -> S3 origin (Polly audio files, immutable, cache 7 days)
  ordered_cache_behavior {
    path_pattern           = "/audio/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 604800  # 7 days
    default_ttl = 604800  # 7 days
    max_ttl     = 2592000 # 30 days
    compress    = true
  }

  # 2. /images/* -> S3 origin (uploaded images, immutable, cache 7 days)
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 604800  # 7 days
    default_ttl = 604800  # 7 days
    max_ttl     = 2592000 # 30 days
    compress    = true
  }

  # 3. /api/* -> Lightsail origin (dynamic API, NO cache)
  # Forwards all headers, query strings, and cookies to the backend.
  # POST/PUT/DELETE must pass through for admin operations.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "lightsail-app"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"] # Forward all headers (Authorization, Content-Type, etc.)
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    compress    = true
  }

  # 4. Default -> Lightsail origin (HTML pages, short cache)
  # HTML pages change on deploy, so a short TTL (5 min) is appropriate.
  # Static assets (CSS, JS) get longer caching via nginx Cache-Control headers.
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "lightsail-app"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    # Short default TTL for HTML pages.
    # nginx sets Cache-Control headers for CSS/JS (5 min) and images (1 day),
    # which CloudFront respects (min_ttl = 0).
    min_ttl     = 0
    default_ttl = 300   # 5 minutes
    max_ttl     = 86400 # 1 day
    compress    = true
  }

  # TLS certificate for HTTPS.
  # sni-only: use Server Name Indication (modern standard, free).
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.blog.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021" # Only allow TLS 1.2+ (secure)
  }

  # No geographic restrictions -- the blog is accessible worldwide.
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

# Points techblog.aws.his4irness23.de to the CloudFront distribution.
# This is an "alias" record (AWS-specific) -- like a CNAME but works at
# the zone apex and doesn't cost extra for DNS queries.
resource "aws_route53_record" "blog" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false # CloudFront handles its own health checks
  }
}
