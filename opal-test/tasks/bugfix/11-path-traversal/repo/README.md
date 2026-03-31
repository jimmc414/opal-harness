# File Server

A minimal Flask application that serves uploaded files from a configurable
directory.

## Usage

```bash
pip install flask
python -m fileserver.app
```

Then browse to `http://localhost:5000/files/readme.txt`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/files/<path:filepath>` | Serve a file from the uploads directory |

## Running Tests

```bash
pytest tests/ -v
```
