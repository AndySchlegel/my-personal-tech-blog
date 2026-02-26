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

# --- IAM Policy: CI/CD (deploy.yml) ---
# Permissions for the deploy pipeline: push Docker images to ECR,
# describe the EKS cluster for kubectl, and authenticate to ECR.
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

# --- IAM Policy: Terraform (terraform.yml) ---
# Permissions for the Terraform pipeline to manage all infrastructure.
# Split into logical groups matching AWS service boundaries.
#
# Why a separate policy? The deploy pipeline only needs ECR push + EKS describe.
# Terraform needs much broader permissions to create/modify/destroy resources.
# Keeping them separate makes it clear which permissions serve which purpose.
resource "aws_iam_role_policy" "terraform" {
  name = "${var.project_name}-terraform-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- Terraform State ---
      # S3: read/write state file. DynamoDB: acquire/release state lock.
      # Without these, terraform init fails because it can't access the backend.
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-terraform-state-his4irness23",
          "arn:aws:s3:::${var.project_name}-terraform-state-his4irness23/*"
        ]
      },
      {
        Sid    = "TerraformLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-terraform-locks"
      },

      # --- STS ---
      # Terraform calls GetCallerIdentity to verify credentials and get account ID.
      # Used by data.aws_caller_identity in multiple modules.
      {
        Sid      = "STS"
        Effect   = "Allow"
        Action   = "sts:GetCallerIdentity"
        Resource = "*"
      },

      # --- VPC + Networking ---
      # Create/manage VPC, subnets, internet gateway, NAT gateway, route tables,
      # elastic IPs, and all associated tags. This is the foundation for everything.
      {
        Sid    = "VPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeSubnets",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DescribeInternetGateways",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:DescribeNatGateways",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:DescribeAddresses",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:DescribeRouteTables",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },

      # --- Security Groups ---
      # Create/manage security groups and their ingress/egress rules.
      # Terraform needs full CRUD to manage the ALB, EKS node, and RDS SGs.
      {
        Sid    = "SecurityGroups"
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ]
        Resource = "*"
      },

      # --- ECR Management ---
      # Terraform creates/deletes the ECR repositories themselves.
      # Different from ECRPushPull above which only pushes images INTO repos.
      {
        Sid    = "ECRManagement"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:ListTagsForResource",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability"
        ]
        Resource = "*"
      },

      # --- S3 Management ---
      # Terraform creates the blog image upload bucket (not the state bucket!).
      # Includes versioning, encryption, CORS, and bucket policies.
      {
        Sid    = "S3Management"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetBucketCORS",
          "s3:PutBucketCORS",
          "s3:DeleteBucketCORS",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration"
        ]
        Resource = "*"
      },

      # --- Cognito ---
      # Create/manage the user pool for admin dashboard authentication.
      # Includes the app client, domain, and user groups.
      {
        Sid    = "Cognito"
        Effect = "Allow"
        Action = [
          "cognito-idp:CreateUserPool",
          "cognito-idp:DeleteUserPool",
          "cognito-idp:DescribeUserPool",
          "cognito-idp:UpdateUserPool",
          "cognito-idp:ListUserPools",
          "cognito-idp:CreateUserPoolClient",
          "cognito-idp:DeleteUserPoolClient",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:UpdateUserPoolClient",
          "cognito-idp:CreateUserPoolDomain",
          "cognito-idp:DeleteUserPoolDomain",
          "cognito-idp:DescribeUserPoolDomain",
          "cognito-idp:CreateGroup",
          "cognito-idp:DeleteGroup",
          "cognito-idp:GetGroup",
          "cognito-idp:ListTagsForResource",
          "cognito-idp:TagResource",
          "cognito-idp:UntagResource"
        ]
        Resource = "*"
      },

      # --- RDS ---
      # Create/manage PostgreSQL instance, subnet groups, and parameter groups.
      # Scoped to our project by naming convention in the Terraform modules.
      {
        Sid    = "RDS"
        Effect = "Allow"
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:ListTagsForResource",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:ModifyDBSubnetGroup",
          "rds:CreateDBParameterGroup",
          "rds:DeleteDBParameterGroup",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBParameters",
          "rds:ModifyDBParameterGroup"
        ]
        Resource = "*"
      },

      # --- EKS Full ---
      # Create/manage the Kubernetes cluster, managed node groups, and addons.
      # The deploy.yml only needs DescribeCluster; Terraform needs full CRUD.
      {
        Sid    = "EKSFull"
        Effect = "Allow"
        Action = [
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:DescribeCluster",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:ListClusters",
          "eks:TagResource",
          "eks:UntagResource",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig",
          "eks:UpdateNodegroupVersion",
          "eks:ListNodegroups",
          "eks:CreateAddon",
          "eks:DeleteAddon",
          "eks:DescribeAddon",
          "eks:DescribeAddonVersions",
          "eks:UpdateAddon",
          "eks:ListAddons",
          "eks:AssociateAccessPolicy",
          "eks:ListAccessPolicies"
        ]
        Resource = "*"
      },

      # --- IAM ---
      # Terraform creates IAM roles for EKS (cluster role, node role),
      # attaches policies, manages OIDC providers, and passes roles to services.
      # This includes the OIDC role itself (self-modification -- safe for plan/apply,
      # but NEVER destroy module.github_oidc from the pipeline!).
      {
        Sid    = "IAM"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PassRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:CreateServiceLinkedRole",
          "iam:GetPolicy",
          "iam:ListPolicyVersions"
        ]
        Resource = "*"
      },

      # --- KMS ---
      # EKS uses a KMS key for secrets encryption at rest.
      # Terraform needs to create the key and manage grants.
      {
        Sid    = "KMS"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:ListAliases",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
      },

      # --- CloudFront ---
      # CDN distribution for blog assets (images from S3).
      # Includes Origin Access Control for secure S3 access.
      {
        Sid    = "CloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:UpdateDistribution",
          "cloudfront:ListDistributions",
          "cloudfront:TagResource",
          "cloudfront:UntagResource",
          "cloudfront:ListTagsForResource",
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:ListOriginAccessControls",
          "cloudfront:CreateCachePolicy",
          "cloudfront:GetCachePolicy",
          "cloudfront:GetOriginAccessControlConfig"
        ]
        Resource = "*"
      },

      # --- ACM ---
      # SSL certificates for blog.his4irness23.de.
      # CloudFront needs a cert in us-east-1, ALB needs one in eu-central-1.
      {
        Sid    = "ACM"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "acm:AddTagsToCertificate",
          "acm:GetCertificate"
        ]
        Resource = "*"
      },

      # --- Route 53 ---
      # DNS records for certificate validation (CNAME) and CloudFront alias (A/AAAA).
      # Read access to hosted zones for data source lookups.
      {
        Sid    = "Route53"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      },

      # --- CloudWatch Logs ---
      # EKS control plane logging writes to CloudWatch Log Groups.
      # Terraform needs to create/manage these log groups.
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:ListTagsForResource",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:ListTagsLogGroup",
          "logs:TagLogGroup"
        ]
        Resource = "*"
      }
    ]
  })
}
