# backup.tf - S3 bucket and write permission for the daily DB backup
#
# Mirrors the homelab backup pattern (same values as the Kuma and OFC
# backup buckets, so there is ONE procedure, not several):
#   - versioning on, Object Lock GOVERNANCE 30 days (WORM: nobody,
#     including a compromised host, can overwrite or delete a backup)
#   - lifecycle expires objects after 35 days, old versions after 1 day
#   - server-side AES256 on top of the client-side age encryption
#   - the instance role may ONLY PutObject into backups/ -- no list,
#     no read, no delete. A takeover of the host can write backups
#     but never read or destroy one.
#
# The only difference to the other hosts: the write permission sits on
# the EC2 instance role (IMDSv2) instead of an IAM user with static
# keys -- this host has a role, so no key material exists at all.

resource "aws_s3_bucket" "db_backup" {
  #checkov:skip=CKV_AWS_144:single-region homelab backup, cross-region replication is out of scope
  #checkov:skip=CKV2_AWS_62:no event notifications needed, the backup script sends its own heartbeat
  #checkov:skip=CKV_AWS_18:access logging not needed for a write-only backup target
  #checkov:skip=CKV_AWS_145:AES256 instead of KMS, content is already age-encrypted client-side
  bucket = "blog-db-backups-his4irness23"

  # Object Lock can only be enabled at bucket creation, never later.
  object_lock_enabled = true
}

# Versioning is a hard requirement for Object Lock (and is what makes
# the 1-day noncurrent-version expiry below meaningful).
resource "aws_s3_bucket_versioning" "db_backup" {
  bucket = aws_s3_bucket.db_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# WORM: every new object is locked for 30 days in GOVERNANCE mode.
# Deleting earlier requires the admin AND --bypass-governance-retention,
# proven against the OFC bucket on 18.08.2026.
resource "aws_s3_bucket_object_lock_configuration" "db_backup" {
  bucket = aws_s3_bucket.db_backup.id
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }
}

# Keep 35 days of backups, drop overwritten versions after a day and
# abandoned multipart uploads after a week -- same numbers as the
# Kuma and OFC buckets.
resource "aws_s3_bucket_lifecycle_configuration" "db_backup" {
  bucket = aws_s3_bucket.db_backup.id

  rule {
    id     = "expire-backups"
    status = "Enabled"
    filter {
      prefix = "backups/"
    }
    expiration {
      days = 35
    }
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "db_backup" {
  bucket = aws_s3_bucket.db_backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# All four public-access locks -- a backup bucket has no readers at all.
resource "aws_s3_bucket_public_access_block" "db_backup" {
  bucket                  = aws_s3_bucket.db_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Write-only permission for the backup script, attached to the existing
# instance role. Deliberately a separate policy (see iam.tf: one policy
# per use case, each with a reason).
resource "aws_iam_role_policy" "db_backup_write" {
  name = "blog-db-backup-write"
  role = aws_iam_role.blog.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BackupWriteOnly"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.db_backup.arn}/backups/*"
      }
    ]
  })
}
