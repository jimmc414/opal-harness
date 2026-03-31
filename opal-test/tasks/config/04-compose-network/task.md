# Task: Docker Compose Service Networking

## Source

Synthetic -- Docker Compose multi-service networking scenario.

## Problem

A Docker Compose setup defines three services (web frontend, API backend, PostgreSQL database) that cannot communicate with each other due to networking misconfiguration. The service names in `docker-compose.yml` do not match what the application config files and environment variables expect, there is no shared custom network, and service startup dependencies are not declared.

## Acceptance Criteria

- `docker-compose.yml` service names match what the config files expect (either rename services or update configs/env vars to be consistent)
- A custom network is defined in `docker-compose.yml` and all services are attached to it
- Service dependencies are declared (`api` depends_on `db`, `web` depends_on `api` -- using whatever final service names are chosen)
- Environment variables in `docker-compose.yml` reference the correct service names
- Config file defaults (`web/config.py`, `api/config.py`) match the compose service names
- `DATABASE_URL` environment variable must reference the correct service name for the postgres container
- Existing tests still pass

## Constraints

- Do not add new Python dependencies
- Do not change the application logic, only fix configuration
- Do not remove any existing services
- Docker is not available; validation is done via the compose file parser and config inspection
