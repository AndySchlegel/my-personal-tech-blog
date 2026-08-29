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

  # NOTE: user_data removed. Lightsail's CreateInstances API has a known issue
  # where Terraform's operation waiter times out even though the instance is
  # created successfully. Instance setup (Docker, swap, etc.) is done via SSH
  # in the deploy-lightsail.yml workflow instead.

  tags = {
    Name = "${var.project_name}-lightsail-${var.environment}"
  }
}

# =============================================================================
# STATIC IP (managed externally -- not importable via Terraform)
# =============================================================================

# The static IP was created during initial provisioning. The AWS provider
# does not support importing aws_lightsail_static_ip into state, so we
# pass the IP address as a variable instead of managing it as a resource.
# The IP persists across instance reboots and is not affected by Terraform.

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

  # SSH access restricted to Tailscale subnet + emergency fallback.
  # Tailscale (100.64.0.0/10) is the primary access path.
  # Home IP can be added temporarily via Terraform variable if needed.
  # fail2ban on the instance provides additional brute-force protection.
  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = var.ssh_allowed_cidrs
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
  records = [var.static_ip_address]
}

# =============================================================================
# IAM USER FOR BACKEND AWS SERVICES
# =============================================================================



