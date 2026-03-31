## Source

Synthetic operations documentation task. A production Flask application has deploy, rollback, health check, and database backup scripts, but no written incident response procedures. On-call engineers need a runbook.

## Problem

The project has working operational scripts in `scripts/` (deploy.sh, rollback.sh, healthcheck.sh, db_backup.sh) but no documentation for incident response. Engineers joining on-call rotations have no reference for standard operating procedures.

Create a comprehensive runbook at `docs/runbook.md` by analyzing the existing scripts and documenting the procedures they implement.

## Acceptance Criteria

- A runbook file exists at `docs/runbook.md`
- Runbook has sections for: Deployment, Rollback, Health Check, Database Backup
- Deployment section lists the deploy steps in order
- Rollback section lists the rollback steps in order
- Each section includes the actual commands to run (not just descriptions)
- Runbook has a "Prerequisites" or "Before You Begin" section listing required access and tools
- Runbook includes a "Troubleshooting" or "Common Issues" section
- Existing tests still pass

## Constraints

- Do not modify the existing scripts
- Do not modify `app/main.py`
- The runbook must be derived from the actual scripts, not generic boilerplate
- The `docs/` directory must be created if it does not exist
