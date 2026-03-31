#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="myapp_${TIMESTAMP}.dump"

pg_dump -Fc myapp > "${BACKUP_DIR}/${FILENAME}"
ln -sf "${BACKUP_DIR}/${FILENAME}" "${BACKUP_DIR}/myapp_latest.dump"

echo "Backup created: ${FILENAME}"
