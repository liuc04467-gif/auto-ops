#!/bin/bash
# OpsLab - MySQL backup script
# Usage: ./backup.sh [database_name]
# Crontab: 0 2 * * * /root/scripts/backup.sh opslab

DB_NAME="${1:-opslab}"
DB_USER="root"
DB_PASS="<REDACTED>"
BACKUP_DIR="/data/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

mysqldump -u"$DB_USER" -p"$DB_PASS" \
  --single-transaction \
  --routines \
  --triggers \
  "$DB_NAME" > "$BACKUP_DIR/${DB_NAME}_${DATE}.sql"

# Compress
gzip "$BACKUP_DIR/${DB_NAME}_${DATE}.sql"

# Cleanup old backups
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$KEEP_DAYS -delete

echo "[$(date)] Backup complete: ${DB_NAME}_${DATE}.sql.gz"
