# iam.tf - IAM roles for EKS cluster, nodes, and service accounts
#
# IAM (Identity and Access Management) controls WHO can do WHAT in AWS.
# Every AWS resource needs an IAM role to operate. Think of roles as
# "permission badges" that resources wear.
#
# Three roles in this file:
#
# 1. Cluster Role
#    WHO: The EKS control plane (API server)
#    WHAT: Manage EC2 instances, networking, logs for the cluster
#    WHY: EKS needs to create/manage ENIs, security groups, and logs
#
# 2. Node Role
#    WHO: EC2 instances (our worker nodes)
#    WHAT: Join the EKS cluster, pull Docker images, manage pod networking
#    WHY: Nodes need permissions to register with EKS, pull from ECR, etc.
#
# 3. ALB Controller Role (IRSA)
#    WHO: The AWS Load Balancer Controller pod (running inside K8s)
#    WHAT: Create and manage Application Load Balancers
#    WHY: When we create a K8s Ingress resource, the controller
#         automatically provisions an ALB in AWS
#
# IRSA (IAM Roles for Service Accounts) is the key concept here:
# Instead of giving the entire NODE broad permissions, we give specific
# PODS only the permissions they need. The ALB controller pod gets ALB
# permissions, but other pods on the same node don't.

# =============================================================================
# 1. EKS CLUSTER ROLE
# =============================================================================

# The "assume_role_policy" (trust policy) says WHO can use this role.
# Here: only the EKS service (eks.amazonaws.com) can assume this role.
# This prevents any other service or user from using these permissions.
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-eks-cluster-role"
  }
}

# Attach the AWS-managed EKS cluster policy.
# This is a pre-built policy by AWS that contains all permissions
# the EKS control plane needs. We don't write these permissions ourselves.
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# =============================================================================
# 2. EKS NODE ROLE
# =============================================================================

# Trust policy: only EC2 instances can assume this role.
# When our spot instances launch, they automatically get this role.
resource "aws_iam_role" "node" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-eks-node-role"
  }
}

# Three AWS-managed policies that every EKS worker node needs:

# 1. Worker Node Policy: allows nodes to register with the EKS cluster,
#    receive pod assignments, and report health status.
resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

# 2. CNI Policy: allows the VPC CNI plugin to manage network interfaces.
#    Each pod gets its own VPC IP address -- the CNI needs permissions
#    to attach/detach ENIs (Elastic Network Interfaces) on the node.
resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

# 3. ECR Read-Only: allows nodes to pull Docker images from our ECR repos.
#    Without this, pods would fail to start with "ImagePullBackOff" errors.
resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# =============================================================================
# 3. OIDC PROVIDER FOR IRSA (IAM Roles for Service Accounts)
# =============================================================================
#
# IRSA is how Kubernetes pods get AWS permissions without giving the
# entire node those permissions. Here's how it works:
#
# 1. EKS cluster creates an OIDC identity provider (like a certificate authority)
# 2. We register this provider with AWS IAM (the resource below)
# 3. When a pod with a specific ServiceAccount starts, EKS injects a JWT token
# 4. The pod uses this token to call sts:AssumeRoleWithWebIdentity
# 5. AWS validates the token against the OIDC provider
# 6. AWS grants temporary credentials for the IAM role
#
# Result: the ALB controller pod can manage ALBs, but the blog-backend
# pod on the same node cannot (it has its own role for S3/Comprehend).

# Fetch the TLS certificate from the EKS OIDC issuer URL.
# AWS needs the certificate thumbprint to trust tokens from this issuer.
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Register the EKS OIDC provider with AWS IAM.
# After this, AWS trusts JWT tokens issued by our EKS cluster.
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.project_name}-eks-oidc"
  }
}

# =============================================================================
# 4. ALB CONTROLLER IRSA ROLE
# =============================================================================
#
# The AWS Load Balancer Controller is a Kubernetes controller that watches
# for Ingress resources and automatically creates/configures ALBs in AWS.
#
# When we deploy a K8s Ingress like:
#   kind: Ingress
#   metadata:
#     annotations:
#       alb.ingress.kubernetes.io/scheme: internet-facing
#   spec:
#     rules:
#       - host: blog.his4irness23.de
#         http:
#           paths:
#             - path: /api/*
#               backend: blog-backend
#             - path: /*
#               backend: blog-frontend
#
# The controller reads this and creates a real AWS ALB with target groups,
# listeners, and rules. It needs broad permissions to do this.

resource "aws_iam_role" "alb_controller" {
  name = "${var.project_name}-alb-controller-role"

  # IRSA trust policy: only the specific Kubernetes ServiceAccount
  # "aws-load-balancer-controller" in the "kube-system" namespace
  # can assume this role. No other pod or service can use it.
  #
  # The Condition block is the key security feature:
  # :sub = the subject (which ServiceAccount is making the request)
  # :aud = the audience (must be sts.amazonaws.com)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-alb-controller-role"
  }
}

# ALB Controller permissions.
# The controller needs to read VPC/subnet/SG info, create/manage ALBs,
# manage security groups for ALB targets, and read ACM certificates.
# This is a simplified version of the official AWS policy document.
resource "aws_iam_role_policy" "alb_controller" {
  #checkov:skip=CKV_AWS_289:ALB controller needs broad ELB permissions per AWS official docs
  #checkov:skip=CKV_AWS_355:ALB controller Resource=* required per AWS official IAM policy
  #checkov:skip=CKV_AWS_290:ALB controller write access is its core purpose (create/manage ALBs)
  name = "${var.project_name}-alb-controller-policy"
  role = aws_iam_role.alb_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Read VPC and network information (to find subnets for ALB)
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeCoipPools",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeInstanceTypes",
          # Full ALB management (create, configure, delete load balancers)
          "elasticloadbalancing:*",
          # Create/manage security groups for ALB targets
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          # Service-linked role for ELB (auto-created on first ALB)
          "iam:CreateServiceLinkedRole",
          # Read Cognito config (for ALB authentication integration)
          "cognito-idp:DescribeUserPoolClient",
          # Read ACM certificates (for HTTPS listeners on ALB)
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          # WAF integration (optional, for web application firewall)
          "waf-regional:*",
          "wafv2:*",
          "shield:*",
          # Tag management
          "tag:GetResources",
          "tag:TagResources"
        ]
        Resource = "*"
      }
    ]
  })
}
