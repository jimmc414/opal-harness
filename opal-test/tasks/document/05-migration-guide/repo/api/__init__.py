from flask import Flask


def create_app():
    app = Flask(__name__)
    from api.v1 import bp as v1_bp
    from api.v2 import bp as v2_bp
    app.register_blueprint(v1_bp, url_prefix='/api/v1')
    app.register_blueprint(v2_bp, url_prefix='/api/v2')
    return app
