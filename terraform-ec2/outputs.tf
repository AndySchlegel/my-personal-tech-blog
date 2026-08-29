# outputs.tf - Values this root exposes after apply
#
# Outputs are the public interface of a root module: what you (or a
# pipeline, or another Terraform root via remote state) need to know
# about the resources without opening the AWS console.

output "instance_id" {
  description = "EC2 instance id, needed for CLI operations (stop, resize, snapshots)"
  value       = aws_instance.blog.id
}

output "public_ip" {
  description = "Public IPv4 of the instance -- SSH target during bootstrap, CloudFront origin later"
  value       = aws_instance.blog.public_ip
}

output "ami_used" {
  description = "AMI the instance was born from (documentation -- later plans ignore AMI drift)"
  value       = aws_instance.blog.ami
}

output "security_group_id" {
  description = "Security group id, needed when rules change via CLI checks"
  value       = aws_security_group.blog.id
}
