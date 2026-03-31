#!/usr/bin/env bash
set -euo pipefail

echo "Starting deployment..."

# 1. Create backup
./scripts/db_backup.sh

# 2. Pull latest code
git pull origin main

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run migrations
python3 -m flask db upgrade

# 5. Restart service
sudo systemctl restart myapp

# 6. Verify health
sleep 5
./scripts/healthcheck.sh

echo "Deployment complete"
