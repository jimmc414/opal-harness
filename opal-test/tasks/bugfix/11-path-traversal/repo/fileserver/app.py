"""Flask file-serving application."""

import os

from flask import Flask, abort, send_file

from fileserver import config

app = Flask(__name__)


@app.route("/files/<path:filepath>")
def serve_file(filepath: str):
    """Serve a file from the uploads directory."""
    full_path = os.path.join(config.UPLOAD_DIR, filepath)

    if not os.path.isfile(full_path):
        abort(404)

    return send_file(full_path)


if __name__ == "__main__":
    app.run(debug=True)
