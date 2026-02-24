# main.tf - GitHub Actions OIDC authentication for CI/CD
#
# This module sets up "keyless" authentication between GitHub Actions and AWS.
# Instead of storing long-lived AWS access keys as GitHub Secrets (risky!),
# we use OIDC (OpenID Connect) federation:
#
#   1. GitHub Actions requests a short-lived JWT token from GitHub's OIDC provider
#   2. The workflow presents this token to AWS STS (Security Token Service)
#   3. AWS validates the token against the OIDC provider we register here
#   4. AWS issues temporary credentials (~1 hour) scoped to our IAM role
#
# Benefits:
#   - No long-lived credentials to rotate or leak
#   - Credentials expire automatically after ~1 hour
#   - Trust is scoped to a specific GitHub repository
#   - AWS CloudTrail logs every assumption for auditing
#
# The workflow uses the aws-actions/configure-aws-credentials@v4 action,
# which handles steps 1-4 automatically. We just need to provide the role ARN.

# --- Current AWS Account ---
# We need the account ID to construct ECR repository ARNs in the policy.
# This is a DATA source (reads info, creates nothing).
data "aws_caller_identity" "current" {}

# --- OIDC Provider ---
# This tells AWS: "trust JWTs signed by GitHub's OIDC provider."
# There's only ONE GitHub OIDC provider globally (token.actions.githubusercontent.com),
# and you only need ONE provider resource per AWS account, even if multiple repos use it.
#
# The thumbprint_list is the TLS certificate fingerprint of GitHub's OIDC endpoint.
# AWS uses this to verify the HTTPS connection to GitHub is authentic.
# This specific thumbprint is GitHub's well-known value (as of 2024).
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # The "audience" (who the token is intended for). GitHub Actions always
  # sets this to "sts.amazonaws.com" when requesting tokens for AWS.
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC TLS certificate thumbprint.
  # This rarely changes. If it does, AWS will reject tokens until updated.
  # You can verify it: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

# --- IAM Role for GitHub Actions ---
# This role is what GitHub Actions "assumes" to get AWS permissions.
# The trust policy (assume_role_policy) controls WHO can assume this role.
# We restrict it to our specific repository -- no other repo can use it.
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  # Trust policy: defines who is allowed to assume this role.
  # Key concept: the "sub" (subject) claim in GitHub's JWT contains the repo info.
  # Format: "repo:owner/repo:ref:refs/heads/branch" or "repo:owner/repo:*"
  #
  # We use "repo:<owner/repo>:*" to allow any branch/tag/PR from our repo.
  # For stricter control, you could limit to specific branches:
  #   "repo:owner/repo:ref:refs/heads/main" -- only main branch
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          # StringEquals: the audience must be sts.amazonaws.com
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # StringLike: the subject must match our repository pattern
          # The "*" allows any branch, tag, or pull_request trigger
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# --- IAM Policy ---
# Defines exactly what GitHub Actions can do in AWS.
# Following least privilege: only the permissions needed for CI/CD.
#
# Three permission groups:
#   1. ECR: push/pull Docker images (build + deploy jobs)
#   2. EKS: get cluster info for kubectl (deploy job)
#   3. ECR Auth: get login token (required before any ECR operation)
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- ECR Authentication ---
      # GetAuthorizationToken is a global action (not scoped to a specific repo).
      # It returns a Docker login token valid for ALL repos in the account.
      # This is why we scope push/pull permissions separately below.
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*" # Must be * -- this action doesn't support resource-level permissions
      },

      # --- ECR Push/Pull ---
      # These actions are scoped to our 2 specific repositories (frontend + backend).
      # No other ECR repos in the account can be accessed.
      #
      # Push flow: InitiateLayerUpload -> UploadLayerPart -> CompleteLayerUpload -> PutImage
      # Pull flow: BatchGetImage + GetDownloadUrlForLayer (needed by EKS to pull images)
      # BatchCheckLayerAvailability: checks if layers already exist (avoids re-uploading)
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = var.ecr_repo_arns # Only our 2 repos: blog-frontend + blog-backend
      },

      # --- EKS ---
      # DescribeCluster returns the API endpoint and CA certificate needed
      # for kubectl to connect. This is what `aws eks update-kubeconfig` uses.
      # Scoped to our specific cluster by name.
      {
        Sid    = "EKSDescribe"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_cluster_name}"
      }
    ]
  })
}
