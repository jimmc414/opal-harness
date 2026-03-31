from flask import Flask


def create_app(env=None):
    app = Flask(__name__)

    app.config['DEBUG'] = True
    app.config['DATABASE_URL'] = 'sqlite:///dev.db'
    app.config['SECRET_KEY'] = 'dev-secret'
    app.config['LOG_LEVEL'] = 'DEBUG'
    app.config['API_RATE_LIMIT'] = 100

    from app.routes import bp
    app.register_blueprint(bp)

    return app
