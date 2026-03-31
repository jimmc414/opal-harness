## Source

Synthetic -- Docker build optimization scenario for a Flask application.

## Problem

The project's Dockerfile is extremely inefficient. It uses a single-stage build that
includes dev dependencies in the production image, breaks Docker layer caching by
copying all source code before installing dependencies, runs as root, and has no
`.dockerignore` to prevent unnecessary files from entering the build context.

The result is a bloated, insecure, and slow-to-build production image.

## Acceptance Criteria

1. Dockerfile uses a multi-stage build (at least 2 `FROM` statements).
2. The final stage uses a slim or alpine Python base image.
3. Requirements files are copied and installed BEFORE source code is copied (layer caching).
4. Dev dependencies (`requirements-dev.txt`) are NOT installed in the final production stage.
5. A non-root `USER` is defined in the final stage.
6. `.dockerignore` excludes at minimum: `.git`, `__pycache__`, `tests/`, `*.pyc`, `.pytest_cache`.
7. The final `CMD` or `ENTRYPOINT` runs the application (gunicorn or flask).
8. `EXPOSE 5000` is present in the Dockerfile.
9. All existing tests continue to pass.
10. The build stage may install dev dependencies for testing, but the final stage must contain only production dependencies.
11. `WORKDIR` must be set in the final stage.

## Constraints

- Do not modify the application code in `app/`.
- Do not modify or remove any existing tests.
- Do not change the contents of `requirements.txt` or `requirements-dev.txt`.
- The application must remain runnable via Flask or Gunicorn on port 5000.
