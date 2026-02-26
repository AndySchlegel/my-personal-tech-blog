# main.tf - ECR repositories for frontend and backend Docker images
#
# ECR (Elastic Container Registry) is AWS's private Docker registry.
# It's like Docker Hub, but private and integrated with AWS IAM.
#
# We need 2 repos:
#   blog-frontend  -> nginx container serving our Tailwind CSS/JS frontend
#   blog-backend   -> Node.js/Express API container
#
# In the CI/CD pipeline, GitHub Actions will:
#   1. Build Docker images from our Dockerfiles
#   2. Tag them (e.g. "v1.0.0", "sha-abc123", "latest")
#   3. Push them to these ECR repos
#   4. EKS pulls from these repos when deploying pods
#
# Lifecycle policies automatically clean up old images to save storage costs.
# Scan on push runs a basic vulnerability check on every new image (free).

# --- Frontend Repository (nginx + static files) ---
resource "aws_ecr_repository" "frontend" {
  #checkov:skip=CKV_AWS_136:KMS encryption costs ~$1/key/month, AES256 sufficient for dev
  #checkov:skip=CKV_AWS_51:Mutable tags needed for latest tag in CI/CD pipeline
  name = "${var.project_name}-frontend"

  # MUTABLE: allows overwriting the "latest" tag on every push.
  # In production, you might use IMMUTABLE to prevent tag overwrites,
  # but MUTABLE is convenient during development.
  image_tag_mutability = "MUTABLE"

  # Automatically scan images for known vulnerabilities (CVEs) when pushed.
  # Results appear in the AWS Console under ECR > Repositories > Scan findings.
  # This is a free, basic scan -- for deeper scanning, AWS Inspector can be added later.
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

# --- Backend Repository (Node.js/Express API) ---
resource "aws_ecr_repository" "backend" {
  #checkov:skip=CKV_AWS_136:KMS encryption costs ~$1/key/month, AES256 sufficient for dev
  #checkov:skip=CKV_AWS_51:Mutable tags needed for latest tag in CI/CD pipeline
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-backend"
  }
}

# --- Lifecycle Policies ---
# Without lifecycle policies, ECR would keep every image forever, accumulating
# storage costs. These policies automatically delete old/unused images.
#
# Rule 1 (priority 1): Delete untagged images after 1 day.
#   Untagged images are leftover layers from failed or superseded builds.
#   They serve no purpose and waste storage.
#
# Rule 2 (priority 2): Keep only the last 10 tagged images.
#   Tags we expect: "v1.0.0", "latest", "sha-abc123" (git commit hash).
#   Once we have more than 10 tagged images, the oldest ones are deleted.
#   This keeps enough history for rollbacks without unlimited growth.

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "sha-"] # Matches our CI tagging convention
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Same lifecycle policy for the backend repo
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
