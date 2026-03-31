from flask import Blueprint, jsonify, request
from app.models import create_item, get_item, get_all_items, update_item, delete_item

bp = Blueprint('api', __name__)


@bp.route('/items')
def list_items():
    return jsonify(get_all_items())


@bp.route('/items/<int:item_id>')
def show_item(item_id):
    item = get_item(item_id)
    if item is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(item)


@bp.route('/items', methods=['POST'])
def new_item():
    data = request.get_json()
    if not data or 'name' not in data or 'price' not in data:
        return jsonify({"error": "name and price required"}), 400
    item = create_item(data['name'], data['price'])
    return jsonify(item), 201


@bp.route('/items/<int:item_id>', methods=['PUT'])
def edit_item(item_id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "data required"}), 400
    item = update_item(item_id, name=data.get('name'), price=data.get('price'))
    if item is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(item)


@bp.route('/items/<int:item_id>', methods=['DELETE'])
def remove_item(item_id):
    item = delete_item(item_id)
    if item is None:
        return jsonify({"error": "not found"}), 404
    return jsonify({"deleted": item_id})
