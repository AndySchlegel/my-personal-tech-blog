# main.tf - VPC with public and private subnets across 2 AZs
#
# Architecture:
#   Public subnets  -> ALB, NAT Gateway (internet-facing)
#   Private subnets -> EKS nodes, RDS (no direct internet access)
#
# Why 2 AZs?
#   EKS requires subnets in at least 2 Availability Zones for high availability.
#   If one AZ goes down, pods can still run in the other AZ.
#
# Why public + private subnets?
#   Public subnets have a route to the Internet Gateway (direct internet access).
#   Private subnets have NO internet route by default -- traffic can only leave
#   through a NAT Gateway (if enabled). This is a security best practice:
#   databases and application servers should never be directly reachable.
#
# NAT Gateway is conditional (var.enable_nat_gateway) to control costs (~$35/month).
# Only enable it when EKS nodes need outbound internet access (pulling Docker
# images, calling AWS APIs, etc.). In Wave 1-2 we keep it off.

# Fetch the list of available AZs in our region (eu-central-1a, eu-central-1b, etc.)
# We use a data source instead of hardcoding AZ names so this works in any region.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Take only the first N AZs (default: 2).
  # slice(["eu-central-1a", "eu-central-1b", "eu-central-1c"], 0, 2)
  # -> ["eu-central-1a", "eu-central-1b"]
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# --- VPC ---
# The VPC is the virtual network that contains ALL our AWS resources.
# Think of it as our own private data center in the cloud.
# CIDR 10.0.0.0/16 gives us 65,536 IP addresses to work with.
resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11:VPC flow logs ~$0.50/GB, enable during deployment sprint
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for RDS -- creates DNS names like mydb.abc123.eu-central-1.rds.amazonaws.com
  enable_dns_support   = true # Required for DNS resolution within the VPC

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# --- Internet Gateway (for public subnets) ---
# The IGW is the "door" between our VPC and the public internet.
# Without it, nothing in the VPC can reach the internet (or be reached).
# Only public subnets route through this -- private subnets don't.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

# --- Public Subnets (10.0.1.0/24, 10.0.2.0/24) ---
# Each subnet gets 256 IP addresses (/24 = 256 IPs, minus 5 reserved by AWS).
# Public subnets are where the ALB and NAT Gateway live.
#
# cidrsubnet("10.0.0.0/16", 8, 1) -> "10.0.1.0/24" (AZ a)
# cidrsubnet("10.0.0.0/16", 8, 2) -> "10.0.2.0/24" (AZ b)
# The "8" adds 8 bits to the /16 prefix, making it /24.
resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Public subnets need public IPs for ALB, that is their purpose
  count = var.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1) # 10.0.1.0/24, 10.0.2.0/24
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true # Instances get a public IP automatically

  tags = {
    Name = "${var.project_name}-public-${local.azs[count.index]}"
    # These tags tell the AWS Load Balancer Controller which subnets to use:
    # "kubernetes.io/role/elb" = "1"        -> Use these subnets for internet-facing ALBs
    # "kubernetes.io/cluster/X" = "shared"  -> This subnet belongs to our EKS cluster
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

# --- Private Subnets (10.0.10.0/24, 10.0.11.0/24) ---
# EKS nodes and RDS live here. No direct internet access.
# The gap in numbering (1,2 vs 10,11) makes it easy to visually
# distinguish public from private subnets in the AWS console.
#
# cidrsubnet("10.0.0.0/16", 8, 10) -> "10.0.10.0/24" (AZ a)
# cidrsubnet("10.0.0.0/16", 8, 11) -> "10.0.11.0/24" (AZ b)
resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10) # 10.0.10.0/24, 10.0.11.0/24
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-${local.azs[count.index]}"
    # "kubernetes.io/role/internal-elb" = "1"  -> Use these for internal (non-internet-facing) ALBs
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

# --- Public Route Table ---
# A route table defines where network traffic goes.
# This one says: "Any traffic going to 0.0.0.0/0 (= the internet)
# should go through the Internet Gateway."
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  # All traffic not destined for the VPC
    gateway_id = aws_internet_gateway.main.id # ... goes to the Internet Gateway
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

# Associate public subnets with the public route table.
# Without this association, subnets use the VPC's default route table
# (which has no internet route).
resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway (conditional, ~$35/month) ---
# The NAT Gateway lets private subnet resources access the internet
# WITHOUT being directly reachable from the internet. One-way door.
#
# Why do EKS nodes need internet?
#   - Pull Docker images from ECR
#   - Call AWS APIs (CloudWatch, Comprehend, S3)
#   - Download Kubernetes add-on updates
#
# Only created when enable_nat_gateway = true (Wave 3).
# count = 0 means "don't create this resource" -- a Terraform pattern
# for conditional resources.

# Elastic IP for the NAT Gateway (a fixed public IP address)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.environment}"
  }
}

# The NAT Gateway itself -- sits in a PUBLIC subnet but serves PRIVATE subnets.
# It translates private IPs to its public EIP for outbound traffic.
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id # Place in first public subnet

  tags = {
    Name = "${var.project_name}-nat-${var.environment}"
  }

  # NAT Gateway needs the IGW to exist first (it routes through it)
  depends_on = [aws_internet_gateway.main]
}

# --- Private Route Table ---
# Private subnets use this route table. When NAT Gateway is enabled,
# it adds a route to send internet traffic through NAT.
# When NAT is disabled, private subnets have NO internet access at all.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}"
  }
}

# Conditional route: only exists when NAT Gateway is enabled.
# "All internet traffic from private subnets goes through NAT Gateway."
resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# Associate private subnets with the private route table.
resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Default Security Group (deny-all) ---
# Every VPC comes with a default SG that allows all inbound/outbound traffic
# between members of the same SG. This is a security risk if resources
# accidentally use it. By claiming it in Terraform with NO rules,
# we ensure the default SG blocks all traffic (deny-all baseline).
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-default-sg-deny-all"
  }
}
