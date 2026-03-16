# main.tf - Lightsail instance for permanent blog hosting
#
# Runs the blog on a single $5/month Lightsail instance with Docker.
# CloudFront sits in front for HTTPS termination and caching.
#
# Architecture:
#   CloudFront -> Lightsail:80 -> nginx (static + /api proxy) -> backend:3000
#                                                               -> db:5432 (Docker volume)
#
# Why Lightsail instead of EC2?
#   - Fixed $5/month pricing (no surprise bills)
#   - Includes 2TB data transfer (EC2 charges per GB)
#   - Simple management for a personal blog
#   - Static IP included at no extra cost

# =============================================================================
# SSH KEY PAIR
# =============================================================================

# Key pair for SSH access during deployment.
# The public key is passed in from GitHub Secrets.
resource "aws_lightsail_key_pair" "deploy" {
  count      = var.ssh_public_key != "" ? 1 : 0
  name       = "${var.project_name}-lightsail-key"
  public_key = var.ssh_public_key
}

# =============================================================================
# LIGHTSAIL INSTANCE
# =============================================================================

resource "aws_lightsail_instance" "blog" {
  name              = "${var.project_name}-lightsail-${var.environment}"
  availability_zone = var.availability_zone
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = var.ssh_public_key != "" ? aws_lightsail_key_pair.deploy[0].name : null

  # Cloud-init script runs once on first boot.
  # Installs Docker, creates swap, prepares the /opt/blog directory.
  user_data = file("${path.module}/user-data.sh")

  tags = {
    Name = "${var.project_name}-lightsail-${var.environment}"
  }
}

# =============================================================================
# STATIC IP
# =============================================================================

# A static IP ensures the instance keeps the same public IP across reboots.
# Without this, the IP changes on every stop/start, breaking DNS and SSH.
resource "aws_lightsail_static_ip" "blog" {
  name = "${var.project_name}-lightsail-ip"
}

resource "aws_lightsail_static_ip_attachment" "blog" {
  static_ip_name = aws_lightsail_static_ip.blog.name
  instance_name  = aws_lightsail_instance.blog.name
}

# =============================================================================
# FIREWALL (PUBLIC PORTS)
# =============================================================================

# Only allow HTTP (80) and SSH (22).
# HTTPS is handled by CloudFront -- the instance only needs port 80.
resource "aws_lightsail_instance_public_ports" "blog" {
  instance_name = aws_lightsail_instance.blog.name

  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }
}

# =============================================================================
# ORIGIN DNS RECORD
# =============================================================================

# CloudFront requires a domain name as origin, not an IP address.
# This A record maps origin-lightsail.aws.his4irness23.de to the static IP.
# CloudFront uses this domain name as the Lightsail origin.
resource "aws_route53_record" "origin" {
  zone_id = var.route53_zone_id
  name    = "origin-lightsail.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_lightsail_static_ip.blog.ip_address]
}

# =============================================================================
# IAM USER FOR BACKEND AWS SERVICES
# =============================================================================

# On EKS, the backend used IRSA (IAM Roles for Service Accounts) for AWS access.
# On Lightsail, we need an IAM user with access keys instead.
# The backend container reads these keys from environment variables.
resource "aws_iam_user" "lightsail_backend" {
  #checkov:skip=CKV_AWS_273:IAM user needed for Lightsail (no IRSA outside EKS)
  name = "${var.project_name}-lightsail-backend"

  tags = {
    Name = "${var.project_name}-lightsail-backend"
  }
}

# Policy: same permissions as the EKS backend IRSA role.
# Comprehend (auto-tags, sentiment), Translate (DE/EN), Polly (TTS), S3 (audio/images).
resource "aws_iam_user_policy" "lightsail_backend" {
  #checkov:skip=CKV_AWS_40:Inline policy is intentional for single-purpose user
  #checkov:skip=CKV_AWS_355:Comprehend/Translate/Polly APIs don't support resource-level ARNs
  name = "${var.project_name}-lightsail-backend-policy"
  user = aws_iam_user.lightsail_backend.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ComprehendAccess"
        Effect = "Allow"
        Action = [
          "comprehend:DetectKeyPhrases",
          "comprehend:DetectSentiment"
        ]
        Resource = "*"
      },
      {
        Sid    = "TranslateAccess"
        Effect = "Allow"
        Action = [
          "translate:TranslateText"
        ]
        Resource = "*"
      },
      {
        Sid    = "PollyAccess"
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      }
    ]
  })
}

# Access keys for the backend container.
# These are passed as environment variables via .env file on the instance.
resource "aws_iam_access_key" "lightsail_backend" {
  user = aws_iam_user.lightsail_backend.name
}
