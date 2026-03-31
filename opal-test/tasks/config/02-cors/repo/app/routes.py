from flask import Blueprint, jsonify, request
from app.models import ITEMS

bp = Blueprint('api', __name__)


@bp.route('/api/items')
def list_items():
    return jsonify(ITEMS)


@bp.route('/api/items', methods=['POST'])
def create_item():
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({"error": "name required"}), 400
    item = {"id": len(ITEMS) + 1, "name": data["name"], "price": data.get("price", 0)}
    ITEMS.append(item)
    return jsonify(item), 201
