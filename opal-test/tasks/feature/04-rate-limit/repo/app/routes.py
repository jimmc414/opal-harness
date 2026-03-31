from flask import Blueprint, jsonify
from app.models import ITEMS

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
