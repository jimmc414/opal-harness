from flask import Blueprint, jsonify

bp = Blueprint('main', __name__)


@bp.route('/')
def index():
    return jsonify({"message": "Hello, World!"})


@bp.route('/health')
def health():
    return jsonify({"status": "healthy"})
