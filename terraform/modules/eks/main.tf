# main.tf - EKS cluster with spot instance node group
#
# EKS (Elastic Kubernetes Service) is AWS's managed Kubernetes.
# AWS manages the control plane (API server, etcd, scheduler) -- we only
# pay for and manage the worker nodes that run our containers.
#
# Architecture:
#   EKS Control Plane (managed by AWS, ~$73/month)
#     |
#     +-- Node Group: 2x Spot t3.medium/t3a.medium (~$53/month total)
#           |
#           +-- Pod: blog-frontend (nginx)
#           +-- Pod: blog-backend (Express)
#           +-- Pod: coredns (DNS for service discovery)
#           +-- Pod: aws-load-balancer-controller (manages ALB)
#
# The cluster runs in private subnets but has a public API endpoint
# so we can run kubectl from our local machine.
#
# Spot instances save ~70% vs on-demand but can be interrupted with
# 2 minutes notice. By specifying multiple instance types (t3 + t3a),
# AWS has more capacity pools to choose from, reducing interruption risk.
#
# OIDC provider enables IRSA (IAM Roles for Service Accounts) --
# a way to give individual pods specific AWS permissions without
# giving the entire node those permissions. See iam.tf for details.

# --- EKS Cluster ---
# The control plane -- this is the "brain" of Kubernetes.
# It decides which pods run where, handles API requests (kubectl),
# and maintains the desired state of all workloads.
resource "aws_eks_cluster" "main" {
  #checkov:skip=CKV_AWS_39:Public endpoint needed for kubectl from local + GitHub Actions
  #checkov:skip=CKV_AWS_38:CIDR restriction not feasible with dynamic GitHub Actions IPs
  #checkov:skip=CKV_AWS_37:Control plane logging ~$0.50/GB, enable during sprint only
  #checkov:skip=CKV2_AWS_64:KMS default key policy sufficient for EKS secrets encryption
  name     = "${var.project_name}-eks-${var.environment}"
  version  = var.cluster_version      # Kubernetes version (1.31)
  role_arn = aws_iam_role.cluster.arn # IAM role that EKS assumes (see iam.tf)

  vpc_config {
    # EKS needs both public and private subnets:
    # - Private subnets: where worker nodes actually run
    # - Public subnets: for the EKS-managed ENIs (network interfaces) and ALB
    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)

    # API endpoint access:
    # Public = true:  we can run kubectl from our laptop
    # Private = true: nodes communicate with the API server within the VPC
    #                 (faster, doesn't go through the internet)
    endpoint_public_access  = true
    endpoint_private_access = true

    # Attach our custom security group to control network access
    security_group_ids = [var.node_security_group_id]
  }

  # Encrypt Kubernetes secrets at rest using our KMS key.
  # Without this, secrets (database passwords, API keys stored in K8s)
  # would be stored in plain text in etcd. This is a security best practice.
  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  # The cluster needs its IAM role to be ready before it can be created.
  # depends_on ensures Terraform creates the role attachment first.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = {
    Name = "${var.project_name}-eks-${var.environment}"
  }
}

# --- KMS Key for Secrets Encryption ---
# KMS (Key Management Service) manages encryption keys.
# This key is used to encrypt/decrypt Kubernetes secrets in etcd.
# Cost: $1/month per key + $0.03 per 10,000 API calls (negligible).
# enable_key_rotation automatically rotates the key annually for security.
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7 # Wait 7 days before permanently deleting (safety net)
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-eks-kms-${var.environment}"
  }
}

# --- Managed Node Group (Spot Instances) ---
# A node group is a set of EC2 instances that register as Kubernetes nodes.
# "Managed" means AWS handles node provisioning, updates, and replacement.
#
# Spot instances:
#   Regular (on-demand) t3.medium = ~$0.042/hour
#   Spot t3.medium                = ~$0.013/hour (70% cheaper!)
#   Trade-off: AWS can reclaim spot instances with 2 minutes notice.
#   Mitigation: we use 2 instance types (t3 + t3a) across 2 AZs,
#   so if one type/AZ is reclaimed, the other is likely still available.
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes-${var.environment}"
  node_role_arn   = aws_iam_role.node.arn  # IAM role for EC2 instances (see iam.tf)
  subnet_ids      = var.private_subnet_ids # Nodes run in private subnets

  # Spot configuration: multiple instance types improve availability
  # t3.medium:  2 vCPU, 4 GB RAM (Intel)
  # t3a.medium: 2 vCPU, 4 GB RAM (AMD, slightly cheaper)
  # Both are compatible -- our containers don't care about the CPU brand.
  capacity_type  = "SPOT"
  instance_types = var.node_instance_types
  disk_size      = 20 # 20 GB EBS volume for Docker images and container logs

  # Scaling configuration:
  # desired = 2: run 2 nodes normally (one per AZ for availability)
  # min = 1:     allow scaling down to 1 node during low traffic
  # max = 3:     allow scaling up to 3 nodes during high traffic
  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  # During node updates (e.g., AMI upgrade), only take down 1 node at a time.
  # This ensures the blog stays available during rolling updates.
  update_config {
    max_unavailable = 1
  }

  # Nodes need their IAM policies to be attached before they can join the cluster.
  # These three policies are the minimum required for EKS worker nodes.
  depends_on = [
    aws_iam_role_policy_attachment.node_worker, # Basic EKS node permissions
    aws_iam_role_policy_attachment.node_cni,    # VPC networking for pods
    aws_iam_role_policy_attachment.node_ecr     # Pull Docker images from ECR
  ]

  tags = {
    Name = "${var.project_name}-nodes-${var.environment}"
  }
}

# --- EKS Managed Add-ons ---
# These are core Kubernetes components that AWS manages for us.
# They're automatically updated when you upgrade the cluster version.

# CoreDNS: provides DNS-based service discovery within the cluster.
# When a pod calls "http://blog-backend:3000", CoreDNS resolves that
# to the actual pod IP address. Essential for microservice communication.
# Needs nodes to be running first (depends_on node group).
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy: maintains network rules on each node.
# It enables Kubernetes Services (the virtual IPs that load-balance
# traffic across multiple pod replicas). Runs as a DaemonSet on every node.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

# VPC CNI (Container Network Interface): gives each pod its own
# VPC IP address. This means pods can communicate directly with other
# AWS resources (like RDS) using standard VPC networking -- no need
# for special proxy or overlay networks.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}
