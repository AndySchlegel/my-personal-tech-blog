# main.tf - RDS PostgreSQL instance
#
# RDS (Relational Database Service) is AWS's managed database.
# Instead of installing and maintaining PostgreSQL ourselves on an EC2 instance,
# AWS handles backups, patching, encryption, and failover.
#
# Our blog uses PostgreSQL to store:
#   - Blog posts (title, content in Markdown, excerpts)
#   - Comments (with sentiment analysis scores from Comprehend)
#   - Tags and categories
#   - Admin user sessions
#
# Security: Runs in private subnets, accessible ONLY from EKS nodes.
# The RDS SG ensures no direct internet access is possible.
#
# PostgreSQL 16 matches our local docker-compose setup for dev/prod parity.
#
# Cost control: db.t3.micro costs ~$13/month, but can be STOPPED for up
# to 7 days at a time (AWS auto-starts it after 7 days). Stop it when
# not actively developing:
#   aws rds stop-db-instance --db-instance-identifier blog-rds-dev

# --- DB Subnet Group ---
# Tells RDS which subnets it can launch in. Must span at least 2 AZs
# (AWS requirement, even for single-AZ deployments). RDS uses this
# to know where to place the instance and where to failover if needed.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-${var.environment}"
  subnet_ids = var.subnet_ids # Our 2 private subnets from the VPC module

  tags = {
    Name = "${var.project_name}-db-subnet-${var.environment}"
  }
}

# --- Custom Parameter Group ---
# Parameter groups control PostgreSQL configuration settings.
# Using a custom group (instead of the default) lets us tweak settings
# for our needs. The "family" must match the engine version (postgres16).
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-pg16-${var.environment}"
  family = "postgres16"

  # Log ALL SQL statements during development.
  # This is invaluable for debugging slow queries and understanding
  # what the backend is doing. In production, you'd set this to "ddl"
  # (only log schema changes) or "none" for performance.
  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = {
    Name = "${var.project_name}-pg16-${var.environment}"
  }
}

# --- The RDS Instance ---
resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_157:Multi-AZ disabled for dev (cost savings, +$13/month)
  #checkov:skip=CKV_AWS_293:Deletion protection off for easy terraform destroy in dev
  #checkov:skip=CKV_AWS_161:IAM DB auth adds complexity, password auth sufficient for blog
  #checkov:skip=CKV_AWS_353:Performance Insights deferred, enable during deployment sprint
  #checkov:skip=CKV_AWS_118:Enhanced monitoring needs IAM role + costs, deferred
  #checkov:skip=CKV_AWS_129:PostgreSQL logging configured via parameter group (log_statement=all)
  #checkov:skip=CKV2_AWS_69:RDS uses SSL by default in VPC, explicit force_ssl not needed for private subnet
  identifier = "${var.project_name}-rds-${var.environment}"

  # Engine configuration
  # Must match our docker-compose postgres:16 for dev/prod consistency.
  # If the backend works locally, it should work the same on RDS.
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class # db.t3.micro: 2 vCPU, 1 GB RAM (~$13/month)

  # Storage configuration
  # 20 GB is the minimum for gp3. gp3 is the newest SSD type with
  # 3,000 IOPS baseline (free) -- more than enough for a blog.
  # storage_encrypted uses the default AWS KMS key (free).
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Database settings
  # These match the docker-compose environment variables so our backend
  # connection string works the same locally and in production.
  db_name  = var.db_name     # "techblog" -- the database name
  username = var.db_username # "bloguser" -- the master username
  password = var.db_password # Set in terraform.tfvars (sensitive, never committed)
  port     = 5432            # Standard PostgreSQL port

  # Networking: private subnets only, no public access
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id] # RDS SG: only accepts traffic from EKS nodes
  publicly_accessible    = false                   # NEVER expose the database to the internet

  # Apply our custom parameter group (with log_statement = "all")
  parameter_group_name = aws_db_parameter_group.main.name

  # Single-AZ deployment (no failover replica).
  # Multi-AZ doubles the cost (~$26/month) for automatic failover.
  # For a dev blog, single-AZ is fine -- we have backups if something fails.
  multi_az = false #tfsec:ignore:aws-rds-enable-multi-az -- single-AZ is intentional for cost

  # Automatic backups: keeps daily snapshots for 7 days.
  # If the database gets corrupted, we can restore to any point
  # within the last 7 days (point-in-time recovery).
  # Backup window: 3-4 AM UTC (quiet hours, no user traffic).
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  # Maintenance window: when AWS applies minor version updates and patches.
  # Monday 4-5 AM UTC to avoid overlap with the backup window.
  # auto_minor_version_upgrade keeps PostgreSQL patched automatically.
  maintenance_window         = "Mon:04:00-Mon:05:00"
  auto_minor_version_upgrade = true

  # Dev settings: allow fast cleanup without creating a final snapshot.
  # In production, you'd set skip_final_snapshot = false and
  # deletion_protection = true to prevent accidental deletion.
  skip_final_snapshot   = true
  deletion_protection   = false # Enable for production!
  copy_tags_to_snapshot = true  # Copy resource tags to automated backups and snapshots

  tags = {
    Name = "${var.project_name}-rds-${var.environment}"
  }
}
