# MyApp

A Flask-based web service with operational scripts for deployment and maintenance.

## Structure

- `app/` - Flask application
- `scripts/` - Operational scripts (deploy, rollback, healthcheck, backup)
- `tests/` - Test suite

## Running

```bash
flask run
```

## Scripts

- `scripts/deploy.sh` - Full deployment procedure
- `scripts/rollback.sh` - Rollback to previous version
- `scripts/healthcheck.sh` - Verify service is healthy
- `scripts/db_backup.sh` - Create database backup
