from flask import Blueprint, jsonify, request
from app.models import ITEMS, get_next_id

bp = Blueprint('api', __name__)


@bp.route('/items')
def list_items():
    return jsonify(ITEMS)


@bp.route('/items/<int:item_id>')
def get_item(item_id):
    item = next((i for i in ITEMS if i['id'] == item_id), None)
    if item is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(item)


@bp.route('/items', methods=['POST'])
def create_item():
    data = request.get_json()
    if not data or 'name' not in data or 'price' not in data:
        return jsonify({"error": "name and price required"}), 400
    item = {"id": get_next_id(), "name": data["name"], "price": data["price"]}
    ITEMS.append(item)
    return jsonify(item), 201
