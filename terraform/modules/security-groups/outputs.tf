# outputs.tf - Security Groups module outputs
#
# Each SG ID is passed to the module that needs it:
#   alb_sg_id      -> EKS module (ALB Ingress controller uses this)
#   eks_node_sg_id -> EKS module (attached to worker node instances)
#   rds_sg_id      -> RDS module (attached to the database instance)

output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "eks_node_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}
