# main.tf - Root module wiring all infrastructure together
#
# This is the "orchestrator" that connects the EKS-specific modules.
# Each module block creates a set of related resources, and this file
# passes outputs from one module as inputs to another.
#
# Example chain: VPC module creates subnets -> RDS module uses those subnet IDs
#
# NOTE: S3, CloudFront, Lightsail, and Cognito have been moved to terraform-lightsail/.
# This root module now only manages EKS-related infrastructure.
# Cognito and S3 are referenced via data sources (managed by terraform-lightsail/).
#
# DEPLOYMENT WAVES (cost-controlled rollout):
# ============================================
# We don't deploy everything at once. Instead, we use -target flags
# to deploy in waves, controlling costs at each stage.
#
# Wave 1 (free/cheap): VPC, Security Groups, ECR, GitHub OIDC
#   terraform apply -target=module.vpc -target=module.security_groups \
#     -target=module.ecr -target=module.github_oidc
#
# Wave 2 (~$13/month): RDS
#   terraform apply -target=module.rds
#
# Wave 3 (~$126/month): EKS (deployment sprint only)
#   Set enable_nat_gateway = true first!
#   terraform apply
#
# After sprint: destroy EKS, disable NAT GW, stop RDS -> back to ~$0.65/month

locals {
  # Construct the full blog domain from subdomain + base domain.
  # "blog" + "aws.his4irness23.de" -> "blog.aws.his4irness23.de"
  blog_domain = "${var.blog_subdomain}.${var.domain_name}"
}

# Look up the existing Route 53 hosted zone for his4irness23.de.
# This is a DATA source (read-only) -- it references an existing zone,
# it does NOT create a new one. The hosted zone was created when
# the domain was registered.
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# ==================== WAVE 1: Foundation (free/cheap) ====================

# VPC: the virtual network containing all our resources.
# Creates public subnets (for ALB), private subnets (for EKS/RDS),
# internet gateway, route tables, and optional NAT gateway.
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  eks_cluster_name   = "${var.project_name}-eks-${var.environment}"
}

# Security Groups: firewall rules controlling traffic between layers.
# Depends on VPC (needs vpc_id and cidr_block from the VPC module).
module "security_groups" {
  source = "./modules/security-groups"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id         # Output from VPC module
  vpc_cidr_block = module.vpc.vpc_cidr_block # Output from VPC module
}

# ECR: Docker image registries for frontend and backend containers.
# No dependencies on VPC -- ECR is a global service within the region.
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

# GitHub OIDC: Keyless authentication for CI/CD pipeline.
# Creates an IAM role that GitHub Actions can assume via OIDC federation.
# No long-lived AWS credentials needed -- just set the role ARN as a GitHub Secret.
# After apply: terraform output -raw github_actions_role_arn -> set as AWS_ROLE_ARN secret.
module "github_oidc" {
  source = "./modules/github-oidc"

  project_name      = var.project_name
  github_repository = var.github_repository
  aws_region        = var.aws_region
  eks_cluster_name  = "${var.project_name}-eks-${var.environment}"
  ecr_repo_arns     = [module.ecr.frontend_repo_arn, module.ecr.backend_repo_arn]
}

# --- Cognito (managed by terraform-lightsail/, referenced here) ---
# The Cognito user pool is permanently managed by the Lightsail root.
# EKS references it via data source to get the pool ID for deploy.yml.
data "aws_cognito_user_pools" "admin" {
  name = "${var.project_name}-admin-pool"
}

# ALB ACM Certificate: SSL cert for the Application Load Balancer.
# Only needed for EKS (ALB Ingress). Controlled by create_alb_cert variable
# to prevent the for_each evaluation from blocking Lightsail-only operations.
# When Lightsail runs alone, these resources don't exist in state and the
# dynamic for_each on domain_validation_options would cause "Invalid for_each" errors.
resource "aws_acm_certificate" "alb" {
  count             = var.create_alb_cert ? 1 : 0
  domain_name       = local.blog_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-alb-cert"
  }
}

resource "aws_route53_record" "alb_cert_validation" {
  for_each = var.create_alb_cert ? {
    for dvo in aws_acm_certificate.alb[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  count                   = var.create_alb_cert ? 1 : 0
  certificate_arn         = aws_acm_certificate.alb[0].arn
  validation_record_fqdns = [for record in aws_route53_record.alb_cert_validation : record.fqdn]
}

# ==================== WAVE 2: Database (~$13/month) ====================

# RDS: Managed PostgreSQL database.
# Depends on VPC (private subnets) and Security Groups (RDS SG).
module "rds" {
  source = "./modules/rds"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.vpc.private_subnet_ids    # Place RDS in private subnets
  security_group_id = module.security_groups.rds_sg_id # Only EKS nodes can connect
  instance_class    = var.rds_instance_class
  db_name           = var.rds_db_name
  db_username       = var.rds_db_username
  db_password       = var.db_password
}

# ==================== WAVE 3: EKS + CDN (deployment sprint) ====================

# EKS: Kubernetes cluster with spot instance worker nodes.
# Depends on VPC (subnets) and Security Groups (node SG).
# Remember: enable_nat_gateway must be true before deploying this!
module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  node_security_group_id = module.security_groups.eks_node_sg_id
  cluster_version        = var.eks_cluster_version
  node_instance_types    = var.eks_node_instance_types
  node_desired           = var.eks_node_desired
  node_min               = var.eks_node_min
  node_max               = var.eks_node_max
  s3_bucket_arn          = data.aws_s3_bucket.assets.arn
}

# Cross-module SG rule: allow EKS pods to reach RDS on port 5432.
# EKS creates its own "cluster security group" and attaches it to all nodes.
# Our custom EKS node SG (from security-groups module) is passed to the
# cluster config but NOT used by managed node groups. So the existing
# RDS ingress rule (which references our custom SG) doesn't match.
# This rule adds the EKS-managed cluster SG as a second allowed source.
# Lives in root main.tf because it connects two modules (EKS + SG).
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks_cluster_sg" {
  security_group_id            = module.security_groups.rds_sg_id
  description                  = "PostgreSQL from EKS cluster SG (pods)"
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# Cross-module SG rules: allow ALB to reach pods on port 80.
# Same issue as the RDS rule above (Lesson #23): EKS managed node groups
# use the auto-created cluster SG, not our custom eks_nodes SG.
# The ALB egress rule in security-groups module references the custom SG,
# so it doesn't match. These rules connect ALB SG to the actual cluster SG.
# When security-groups annotation is set on the Ingress, the ALB Controller
# does NOT auto-manage SG rules -- we must add them ourselves.
resource "aws_vpc_security_group_egress_rule" "alb_to_eks_cluster_sg" {
  security_group_id            = module.security_groups.alb_sg_id
  description                  = "Forward traffic to EKS pods (cluster SG)"
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_sg_from_alb" {
  #checkov:skip=CKV_AWS_260:Port 80 is SG-to-SG only (ALB->pods), not open to internet
  security_group_id            = module.eks.cluster_security_group_id
  description                  = "HTTP from ALB (target-type ip)"
  referenced_security_group_id = module.security_groups.alb_sg_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# --- S3 (managed by terraform-lightsail/, referenced here) ---
# The S3 bucket for blog assets is permanently managed by the Lightsail root.
# EKS references it via data source for IRSA permissions (Polly audio upload).
data "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-assets-his4irness23"
}

# NOTE: CloudFront, Lightsail, and S3 modules have been moved to terraform-lightsail/.
# They are no longer managed by this EKS root module.
