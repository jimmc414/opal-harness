# Flask App

A minimal Flask application with health check endpoint.

## Running Locally

```bash
pip install -r requirements.txt
flask run --host=0.0.0.0
```

## Running with Docker

```bash
docker build -t flask-app .
docker run -p 5000:5000 flask-app
```

## Testing

```bash
pip install -r requirements-dev.txt
pytest
```
