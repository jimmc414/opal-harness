#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Running all tests ==="
python -m pytest tests/ -v

echo "=== Verifying env override inline ==="
APP_PORT=9999 APP_DEBUG=0 python -c "
import os, json
os.environ['APP_PORT'] = '9999'
os.environ['APP_DEBUG'] = '0'
from config.loader import load_config
cfg = load_config(config_file='fixtures/sample_config.json')
assert cfg['port'] == 9999, f\"Expected port 9999, got {cfg['port']}\"
assert cfg['debug'] is False, f\"Expected debug False, got {cfg['debug']}\"
print('Inline env override verification passed.')
"

echo "=== All checks passed ==="
