# main.tf - S3 bucket for blog image uploads
#
# This bucket stores all images uploaded through the admin dashboard
# (blog post thumbnails, screenshots, diagrams, etc.).
#
# Security model:
#   ALL public access is blocked. No one can access images directly via S3 URLs.
#   Images are served exclusively through CloudFront via Origin Access Control (OAC).
#   This means: users see https://blog.his4irness23.de/images/photo.jpg (CloudFront)
#   but NEVER the raw S3 URL. CloudFront handles caching, HTTPS, and access control.
#
# Upload flow:
#   Admin dashboard -> Backend API generates pre-signed URL -> Browser uploads to S3.
#   Pre-signed URLs are temporary (expire after minutes) and scoped to a specific key.

# --- The S3 Bucket ---
# Bucket names must be globally unique across ALL AWS accounts.
# We append a unique suffix to ensure no collision.
resource "aws_s3_bucket" "assets" {
  #checkov:skip=CKV_AWS_144:Cross-region replication overkill for blog images, single bucket sufficient
  #checkov:skip=CKV_AWS_18:Access logging needs dedicated bucket, deferred to production
  #checkov:skip=CKV_AWS_145:KMS encryption costs extra, SSE-S3 (AES256) sufficient for dev
  #checkov:skip=CKV2_AWS_62:S3 event notifications not needed, no Lambda triggers planned
  bucket = "${var.project_name}-assets-his4irness23"

  tags = {
    Name = "${var.project_name}-assets-${var.environment}"
  }
}

# --- Versioning ---
# Keeps previous versions of overwritten/deleted files.
# If someone accidentally deletes an image or uploads a wrong version,
# we can restore the previous version from the S3 console.
# Small storage overhead but worth it as a safety net.
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Server-side Encryption ---
# AES256 (SSE-S3) encrypts all objects at rest using AWS-managed keys.
# This is free and automatic -- every object is encrypted before being
# written to disk. Required for security compliance and best practices.
# Alternative: SSE-KMS uses your own key (costs $1/month per key).
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Block ALL Public Access ---
# This is the most important security setting on the bucket.
# Even if someone accidentally adds a public bucket policy or ACL,
# these settings override and block it. Belt AND suspenders.
#
# All four settings must be true for complete protection:
#   block_public_acls       -> Rejects PUT requests with public ACLs
#   block_public_policy     -> Rejects bucket policies that grant public access
#   ignore_public_acls      -> Ignores any existing public ACLs
#   restrict_public_buckets -> Restricts access to AWS services and authorized users only
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- CORS Configuration ---
# CORS (Cross-Origin Resource Sharing) controls which websites can
# make requests to our S3 bucket from the browser.
#
# Without CORS: the admin dashboard (running on blog.his4irness23.de)
# would be blocked by the browser when trying to upload images to S3,
# because S3 is a different origin (different domain).
#
# We allow:
#   - GET: CloudFront fetching images (though OAC handles this server-side)
#   - PUT/POST: Admin dashboard uploading images via pre-signed URLs
#   - Our blog domain + localhost for local development
resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]                  # Allow any request headers
    allowed_methods = ["GET", "PUT", "POST"] # Read + upload
    allowed_origins = [
      "https://${var.domain_name}", # Production: blog.his4irness23.de
      "http://localhost:8080"       # Local development
    ]
    max_age_seconds = 3600 # Browser caches CORS preflight response for 1 hour
  }
}

# --- Lifecycle Rule ---
# Automatically moves objects to a cheaper storage class after 90 days.
# STANDARD_IA (Infrequent Access) costs ~40% less than STANDARD storage
# but charges a small fee per access. Perfect for older blog images
# that are rarely viewed but shouldn't be deleted.
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "move-to-ia"
    status = "Enabled"
    filter {} # Empty filter = apply to ALL objects in the bucket

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Clean up incomplete multipart uploads after 7 days.
    # Without this, abandoned uploads consume storage indefinitely.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
