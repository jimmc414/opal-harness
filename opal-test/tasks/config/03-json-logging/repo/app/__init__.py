import logging
from flask import Flask


def create_app():
    app = Flask(__name__)

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    from app.routes import bp
    app.register_blueprint(bp)

    return app
