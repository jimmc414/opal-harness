#!/usr/bin/env bash
set -euo pipefail

echo "Starting rollback..."

# 1. Stop service
sudo systemctl stop myapp

# 2. Revert to previous version
git checkout HEAD~1

# 3. Restore database backup
pg_restore -d myapp /var/backups/myapp_latest.dump

# 4. Restart service
sudo systemctl start myapp

# 5. Verify health
sleep 5
./scripts/healthcheck.sh

echo "Rollback complete"
