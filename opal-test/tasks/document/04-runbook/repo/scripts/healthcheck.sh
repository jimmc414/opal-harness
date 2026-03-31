#!/usr/bin/env bash
set -euo pipefail

response=$(curl -sf http://localhost:5000/health)
if echo "$response" | grep -q '"status":"healthy"'; then
    echo "Health check passed"
    exit 0
else
    echo "Health check FAILED"
    exit 1
fi
