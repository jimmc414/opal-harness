from flask import Blueprint, jsonify, request
from models.items import get_items, get_item, add_item, update_item, remove_item

bp = Blueprint('v1', __name__)


@bp.route('/items')
def list_items():
    items = get_items()
    return jsonify({"data": items, "count": len(items)})


@bp.route('/items/<int:item_id>')
def show_item(item_id):
    item = get_item(item_id)
    if not item:
        return jsonify({"error": "Not found"}), 404
    return jsonify({"data": item})


@bp.route('/items', methods=['POST'])
def create_item():
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({"error": "name required"}), 400
    item = add_item(data['name'], data.get('price', 0), data.get('category', 'general'))
    return jsonify({"data": item}), 201


@bp.route('/items/<int:item_id>', methods=['PUT'])
def edit_item(item_id):
    data = request.get_json()
    item = update_item(item_id, **data)
    if not item:
        return jsonify({"error": "Not found"}), 404
    return jsonify({"data": item})


@bp.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    item = remove_item(item_id)
    if not item:
        return jsonify({"error": "Not found"}), 404
    return jsonify({"data": {"deleted": item_id}})
