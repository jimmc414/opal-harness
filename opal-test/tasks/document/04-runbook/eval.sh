#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Task: document-04-runbook ==="

# Criterion: Existing tests still pass
echo "--- Checking existing tests pass ---"
python3 -m pytest tests/ -q

echo "--- Checking runbook ---"

# Criterion: A runbook file exists at docs/runbook.md
if [ ! -f docs/runbook.md ]; then
    echo "FAIL: docs/runbook.md does not exist"
    exit 1
fi
echo "PASS: docs/runbook.md exists"

RUNBOOK=$(cat docs/runbook.md)

# Criterion: Runbook has sections for Deployment, Rollback, Health Check, Database Backup
for section in "Deployment" "Rollback" "Health Check" "Database Backup"; do
    # Case-insensitive check for section header
    if ! echo "$RUNBOOK" | grep -qi "## .*${section}\|# .*${section}"; then
        # Also try without space for compound words
        alt=$(echo "$section" | tr ' ' '-')
        if ! echo "$RUNBOOK" | grep -qi "## .*${alt}\|# .*${alt}"; then
            echo "FAIL: Missing section for '${section}'"
            exit 1
        fi
    fi
done
echo "PASS: all four main sections present"

# Criterion: Deployment section lists the deploy steps in order
# Check that key deploy commands appear
if ! echo "$RUNBOOK" | grep -q "db_backup"; then
    echo "FAIL: Deployment section should reference db_backup step"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "git pull"; then
    echo "FAIL: Deployment section should include 'git pull' command"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "pip install"; then
    echo "FAIL: Deployment section should include 'pip install' command"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "flask db upgrade"; then
    echo "FAIL: Deployment section should include 'flask db upgrade' command"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "systemctl restart"; then
    echo "FAIL: Deployment section should include 'systemctl restart' command"
    exit 1
fi
echo "PASS: deployment commands present"

# Criterion: Rollback section lists the rollback steps in order
if ! echo "$RUNBOOK" | grep -q "systemctl stop"; then
    echo "FAIL: Rollback section should include 'systemctl stop' command"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "git checkout"; then
    echo "FAIL: Rollback section should include 'git checkout' command"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "pg_restore"; then
    echo "FAIL: Rollback section should include 'pg_restore' command"
    exit 1
fi
echo "PASS: rollback commands present"

# Criterion: Each section includes actual commands (check for code blocks)
code_block_count=$(echo "$RUNBOOK" | grep -c '```' || true)
if [ "$code_block_count" -lt 4 ]; then
    echo "FAIL: Runbook should have at least 4 code blocks (one per section), found $code_block_count"
    exit 1
fi
echo "PASS: code blocks present in runbook"

# Health check commands
if ! echo "$RUNBOOK" | grep -q "curl"; then
    echo "FAIL: Health check section should include 'curl' command"
    exit 1
fi
if ! echo "$RUNBOOK" | grep -q "localhost:5000"; then
    echo "FAIL: Health check section should reference localhost:5000"
    exit 1
fi
echo "PASS: health check commands present"

# Database backup commands
if ! echo "$RUNBOOK" | grep -q "pg_dump"; then
    echo "FAIL: Database backup section should include 'pg_dump' command"
    exit 1
fi
echo "PASS: database backup commands present"

# Criterion: Runbook has a Prerequisites or Before You Begin section
if ! echo "$RUNBOOK" | grep -qi "prerequisit\|before you begin"; then
    echo "FAIL: Missing Prerequisites or Before You Begin section"
    exit 1
fi
echo "PASS: prerequisites section present"

# Criterion (easy-to-miss): Runbook includes a Troubleshooting or Common Issues section
if ! echo "$RUNBOOK" | grep -qi "troubleshoot\|common issue"; then
    echo "FAIL: Missing Troubleshooting or Common Issues section"
    exit 1
fi
echo "PASS: troubleshooting section present"

echo ""
echo "ALL CHECKS PASSED"
echo "=== document-04-runbook: PASS ==="
