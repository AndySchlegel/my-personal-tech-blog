# outputs.tf - RDS module outputs
#
# The backend needs these values for its DATABASE_URL:
#   postgresql://bloguser:<password>@<hostname>:<port>/techblog

output "rds_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.main.endpoint
  # Example: "blog-rds-dev.abc123.eu-central-1.rds.amazonaws.com:5432"
  # This is the full connection string including port.
}

output "rds_hostname" {
  description = "RDS instance hostname (without port)"
  value       = aws_db_instance.main.address
  # Example: "blog-rds-dev.abc123.eu-central-1.rds.amazonaws.com"
  # Use this when the port is specified separately.
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
  # Always 5432 (standard PostgreSQL port)
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
  # "techblog" -- used in the connection string
}
