"""Flask routes for the user profile API."""

from flask import Flask, Blueprint, jsonify
from .models import get_user, get_all_users
from .formatters import format_user

users_bp = Blueprint("users", __name__)


@users_bp.route("/users/", methods=["GET"])
def list_users():
    """Return all users."""
    users = get_all_users()
    return jsonify([format_user(u) for u in users])


@users_bp.route("/users/<int:user_id>", methods=["GET"])
def get_user_endpoint(user_id):
    """Return a single user by ID."""
    user = get_user(user_id)
    if user is None:
        return jsonify({"error": "User not found"}), 404
    return jsonify(format_user(user))


def create_app():
    """Flask application factory."""
    app = Flask(__name__)
    app.register_blueprint(users_bp)
    return app
