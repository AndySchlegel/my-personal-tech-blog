# main.tf - The actual resources: key pair, security group, instance
#
# Deliberately kept in one file: a single host with its firewall does not
# need the module split that the EKS root uses for eight AWS services.
# If this root ever grows (second instance, IAM role, backups), promote
# the pieces into modules/ then -- not before.

# --- SSH key pair -------------------------------------------------------
# Registers the PUBLIC key with AWS so it can be injected into the
# instance's ubuntu user at first boot. The private key never touches
# AWS or this repo -- it stays on the MacBooks only.
resource "aws_key_pair" "blog" {
  key_name   = "blog-ec2-key"
  public_key = var.ssh_public_key
}

# --- Security group -----------------------------------------------------
# The instance firewall. Rule of thumb: inbound closed by default,
# every open port is a documented decision.
resource "aws_security_group" "blog" {
  name        = "blog-ec2-sg"
  description = "Firewall for the blog EC2 host"
  vpc_id      = data.aws_vpc.default.id

  # No SSH ingress: since the Tailscale join (26.08.2026) SSH runs
  # exclusively through the tailnet. The bootstrap rule that allowed
  # port 22 from one admin IP was removed right after -- if you ever
  # need emergency SSH, re-add it here, never in the console.

  # HTTP/HTTPS for the blog itself. Port 80 stays open for the
  # ACME HTTP-01 challenge and the redirect to 443.
  # checkov:skip=CKV_AWS_260:Public webserver -- ports 80/443 open to the world is the purpose, SSH is tailnet-only
  # checkov:skip=CKV_AWS_382:Open egress is a documented decision, see comment on the egress block
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTP public (redirect + ACME challenge)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTPS public (blog traffic, CloudFront origin)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: allow everything. The host must reach apt mirrors, Docker
  # registries, Tailscale and AWS APIs; restricting egress on a single
  # trusted host adds friction without a matching threat model.
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- The instance -------------------------------------------------------
resource "aws_instance" "blog" {
  # checkov:skip=CKV_AWS_126:Detailed (1-min) monitoring costs ~2 USD/month and buys nothing for a low-traffic blog; default 5-min metrics suffice
  # checkov:skip=CKV_AWS_135:t4g delivers EBS-optimized performance by default; setting the flag forces instance REPLACEMENT (measured 27.08.2026) for zero gain
  ami           = data.aws_ami.ubuntu_arm64.id
  instance_type = var.instance_type

  key_name               = aws_key_pair.blog.key_name
  vpc_security_group_ids = [aws_security_group.blog.id]
  iam_instance_profile   = aws_iam_instance_profile.blog.name

  # IMDSv2 only: the instance metadata service answers only to
  # session-token requests. Blocks the classic SSRF attack where a
  # compromised web app reads credentials from 169.254.169.254.
  metadata_options {
    http_tokens   = "required" # this is what "IMDSv2 enforced" means
    http_endpoint = "enabled"
    # Containers sit one network hop further from the metadata service
    # than the host (docker bridge). Limit 2 lets the backend container
    # fetch role credentials via IMDSv2; the default of 1 would block it.
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    encrypted             = true
    delete_on_termination = true # root disk dies with the instance; data worth keeping gets backed up to S3, not parked on a boot disk
  }

  lifecycle {
    # The AMI lookup always points at the newest Ubuntu build. Without
    # this, a plan months from now would want to REPLACE the running
    # instance just because Canonical published a patch release.
    # Policy: the AMI decides how the instance is BORN; after that,
    # updates happen inside via apt, not by rebuilding.
    ignore_changes = [ami]
  }

  tags = {
    Name = "blog-ec2" # shown as the instance name in the console
  }
}
