# data.tf - Data sources: things we look up instead of create
#
# A data source READS from AWS at plan time. Nothing here creates or
# changes anything -- it answers questions like "what is the current
# Ubuntu AMI id" so we never hardcode values that go stale.

# Latest Ubuntu 24.04 LTS (Noble) for arm64, published by Canonical.
# AMI ids differ per region and change with every patch release, so
# hardcoding one means silently installing an outdated image months later.
data "aws_ami" "ubuntu_arm64" {
  most_recent = true             # of all matches, take the newest one
  owners      = ["099720109477"] # Canonical's official AWS account id

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# The default VPC of this region. Every AWS account ships with one;
# for a single instance it is the pragmatic choice -- a dedicated VPC
# (like the EKS root builds) would add subnets, route tables and an
# internet gateway without buying anything for one host.
data "aws_vpc" "default" {
  default = true
}
