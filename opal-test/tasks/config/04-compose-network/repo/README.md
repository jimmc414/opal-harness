# Multi-Service Application

A three-service application using Docker Compose: web frontend, API backend, and PostgreSQL database.

## Services

- **web** - Frontend service (port 8080)
- **api** - Backend API service (port 5000)
- **db** - PostgreSQL database

## Running

```bash
docker-compose up --build
```

## Testing

```bash
pytest tests/
```
