#!/bin/bash
# user-data.sh - Cloud-init script for Lightsail instance
#
# Runs once on first boot. Installs Docker, creates swap space,
# and prepares the /opt/blog directory for the blog deployment.
#
# IMPORTANT: 1GB RAM is tight for PostgreSQL + Node.js + nginx.
# The swap file provides overflow memory to prevent OOM kills.

set -euo pipefail

# --- System updates ---
dnf update -y

# --- Install Docker + docker-compose ---
dnf install -y docker
systemctl enable docker
systemctl start docker

# Install docker-compose v2 (standalone binary)
COMPOSE_VERSION="v2.29.1"
curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Allow ec2-user to run Docker without sudo
usermod -aG docker ec2-user

# --- Create 1GB swap file ---
# CRITICAL: Without swap, the 1GB RAM instance runs out of memory
# during Docker builds or when all 3 containers are running.
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# --- Prepare blog directory ---
mkdir -p /opt/blog
chown ec2-user:ec2-user /opt/blog

# --- Install AWS CLI (for DB backups to S3) ---
dnf install -y aws-cli

echo "Cloud-init complete. Ready for blog deployment."
