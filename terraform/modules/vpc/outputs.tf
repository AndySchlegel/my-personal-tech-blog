# outputs.tf - VPC module outputs
#
# These values are consumed by other modules:
#   vpc_id          -> Security Groups, EKS (to create resources in this VPC)
#   vpc_cidr_block  -> Security Groups (for internal communication rules)
#   public_subnets  -> EKS (for ALB and cluster endpoint)
#   private_subnets -> EKS (for worker nodes), RDS (for database placement)

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (for ALB and NAT Gateway)"
  value       = aws_subnet.public[*].id
  # The [*] syntax collects the "id" from all subnet instances (count = 2)
  # into a list: ["subnet-abc123", "subnet-def456"]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (for EKS nodes and RDS)"
  value       = aws_subnet.private[*].id
}
