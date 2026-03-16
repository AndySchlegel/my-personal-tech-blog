#!/bin/bash
# backup-db.sh - Daily PostgreSQL backup to S3
#
# Dumps the blog database and uploads it to S3.
# Designed to run as a daily cron job on the Lightsail instance.
#
# Usage:
#   ./scripts/backup-db.sh
#
# Prerequisites:
#   - Docker running with the blog db container
#   - AWS CLI configured (uses instance IAM or .env credentials)
#   - S3_BUCKET_NAME environment variable set
#
# Cron setup (add to ec2-user's crontab):
#   0 3 * * * /opt/blog/scripts/backup-db.sh >> /opt/blog/logs/backup.log 2>&1

set -euo pipefail

# Configuration
S3_BUCKET="${S3_BUCKET_NAME:-blog-assets-his4irness23}"
BACKUP_DIR="/opt/blog/backups"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="techblog-${DATE}.sql.gz"
RETENTION_DAYS=7

echo "[$(date)] Starting database backup..."

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Dump the database from the running PostgreSQL container.
# Uses pg_dump inside the container to avoid needing psql on the host.
docker exec blog-db-1 pg_dump -U bloguser techblog | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

FILESIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
echo "[$(date)] Backup created: ${BACKUP_FILE} (${FILESIZE})"

# Upload to S3
aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "s3://${S3_BUCKET}/backups/${BACKUP_FILE}"
echo "[$(date)] Uploaded to s3://${S3_BUCKET}/backups/${BACKUP_FILE}"

# Clean up local backups older than retention period
find "${BACKUP_DIR}" -name "techblog-*.sql.gz" -mtime +${RETENTION_DAYS} -delete
echo "[$(date)] Cleaned up local backups older than ${RETENTION_DAYS} days"

echo "[$(date)] Backup complete."
