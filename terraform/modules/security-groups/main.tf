# main.tf - Security groups for ALB, EKS nodes, and RDS
#
# Security groups act as virtual firewalls for AWS resources.
# Each SG defines which traffic is allowed IN (ingress) and OUT (egress).
#
# Traffic flow (layered security):
#   Internet -> ALB (80/443) -> EKS Nodes (80) -> RDS (5432)
#
# Key principle: each layer only accepts traffic from the previous layer.
# RDS is only reachable from EKS nodes, never from the internet.
# This is called "defense in depth" -- even if one layer is compromised,
# the next layer still blocks unauthorized access.
#
# We use the newer "separate rule" resources (aws_vpc_security_group_ingress_rule)
# instead of inline rules. This is the AWS-recommended pattern because it
# avoids rule conflicts when multiple modules modify the same security group.

# --- ALB Security Group ---
# The Application Load Balancer is the entry point from the internet.
# It accepts HTTP (port 80) and HTTPS (port 443) from anywhere.
resource "aws_security_group" "alb" {
  # name_prefix instead of name: Terraform appends random chars (e.g. "blog-alb-a1b2c3")
  # This prevents naming conflicts during create_before_destroy lifecycle.
  name_prefix = "${var.project_name}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-alb-sg-${var.environment}"
  }

  # create_before_destroy: when updating, create the new SG first, then
  # switch resources over, then delete the old SG. Prevents downtime.
  lifecycle {
    create_before_destroy = true
  }
}

# Allow HTTP traffic from anywhere (will be redirected to HTTPS by ALB)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  cidr_ipv4         = "0.0.0.0/0" # 0.0.0.0/0 = "from anywhere on the internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Allow HTTPS traffic from anywhere (the main entry point for the blog)
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# ALB can only send traffic to EKS nodes on port 80.
# This is a SG-to-SG reference: instead of allowing traffic to an IP range,
# we say "allow traffic to any instance that has the eks_nodes SG attached."
# This is more secure because it adapts automatically when nodes scale.
resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward traffic to EKS nodes"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# --- EKS Nodes Security Group ---
# Worker nodes run our blog containers (frontend nginx + backend Express).
# They accept traffic from the ALB and communicate with each other
# (node-to-node communication is required for Kubernetes networking).
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-eks-nodes-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-eks-nodes-sg-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Accept traffic from ALB only (SG-to-SG reference, same pattern as above)
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# Allow all traffic within the VPC (node-to-node + node-to-control-plane).
# ip_protocol = "-1" means "all protocols" (TCP, UDP, ICMP, etc.)
# Kubernetes needs this for: pod networking, DNS resolution, health checks,
# and communication between the kubelet on each node and the API server.
resource "aws_vpc_security_group_ingress_rule" "nodes_internal" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Node-to-node communication within VPC"
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "-1" # All protocols
}

# Allow all outbound traffic from nodes.
# Nodes need outbound access for: pulling Docker images from ECR,
# calling AWS APIs (S3, Comprehend, CloudWatch), DNS resolution,
# and downloading Kubernetes updates. This is why NAT Gateway is
# needed in Wave 3 -- the nodes are in private subnets but need
# outbound internet access through NAT.
resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow all outbound (image pulls, API calls, DNS)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- RDS Security Group ---
# The database is the most protected layer.
# It ONLY accepts PostgreSQL connections (port 5432) from EKS nodes.
# No internet access, no access from ALB, no access from other services.
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Only EKS nodes can connect to the database.
# Our Express backend (running on EKS) uses this connection to
# read/write blog posts, comments, and tags.
resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from EKS nodes only"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
