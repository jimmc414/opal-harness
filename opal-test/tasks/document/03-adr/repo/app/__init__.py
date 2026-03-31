from flask import Flask, g
import sqlite3


def create_app(db_path=":memory:"):
    app = Flask(__name__)
    app.config['DB_PATH'] = db_path

    from app.routes import bp
    app.register_blueprint(bp)

    return app


def get_db(app=None):
    from flask import current_app
    app = app or current_app
    if 'db' not in g:
        g.db = sqlite3.connect(app.config['DB_PATH'])
        g.db.row_factory = sqlite3.Row
    return g.db
