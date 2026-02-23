# main.tf - Root module wiring all infrastructure together
#
# This is the "orchestrator" that connects all 8 modules.
# Each module block creates a set of related resources, and this file
# passes outputs from one module as inputs to another.
#
# Example chain: VPC module creates subnets -> RDS module uses those subnet IDs
#
# DEPLOYMENT WAVES (cost-controlled rollout):
# ============================================
# We don't deploy everything at once. Instead, we use -target flags
# to deploy in waves, controlling costs at each stage.
#
# Wave 1 (free/cheap): VPC, Security Groups, ECR, S3, Cognito
#   terraform apply -target=module.vpc -target=module.security_groups \
#     -target=module.ecr -target=module.s3 -target=module.cognito
#
# Wave 2 (~$13/month): RDS
#   terraform apply -target=module.rds
#
# Wave 3 (~$126/month): EKS, CloudFront (deployment sprint only)
#   Set enable_nat_gateway = true first!
#   terraform apply
#
# After sprint: destroy EKS, disable NAT GW, stop RDS -> back to ~$0.65/month

locals {
  # Construct the full blog domain from subdomain + base domain.
  # "blog" + "his4irness23.de" -> "blog.his4irness23.de"
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

# S3: Bucket for blog image uploads (served through CloudFront).
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = local.blog_domain # For CORS configuration
}

# Cognito: Admin authentication (JWT tokens for the admin dashboard).
module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  domain_name  = local.blog_domain # For callback URLs
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
}

# CloudFront: CDN for serving blog assets (images) with HTTPS.
# Depends on S3 (origin bucket) and Route 53 (DNS zone for the domain).
# The providers block passes both the default and us-east-1 provider
# because CloudFront needs ACM certificates in us-east-1.
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name                   = var.project_name
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  s3_bucket_arn                  = module.s3.bucket_arn
  s3_bucket_id                   = module.s3.bucket_id
  domain_name                    = local.blog_domain
  route53_zone_id                = data.aws_route53_zone.main.zone_id

  # Pass both AWS providers to this module.
  # The module uses aws.us_east_1 for the ACM certificate.
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
