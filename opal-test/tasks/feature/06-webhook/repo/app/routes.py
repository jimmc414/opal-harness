from flask import Blueprint, jsonify, request
from app.models import create_order, get_order, update_order_status

bp = Blueprint('api', __name__)


@bp.route('/orders', methods=['POST'])
def new_order():
    data = request.get_json()
    if not data or 'customer' not in data or 'items' not in data:
        return jsonify({"error": "customer and items required"}), 400
    order = create_order(data['customer'], data['items'])
    return jsonify(order), 201


@bp.route('/orders/<int:order_id>')
def show_order(order_id):
    order = get_order(order_id)
    if order is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(order)


@bp.route('/orders/<int:order_id>/status', methods=['PUT'])
def change_status(order_id):
    data = request.get_json()
    if not data or 'status' not in data:
        return jsonify({"error": "status required"}), 400
    order = update_order_status(order_id, data['status'])
    if order is None:
        return jsonify({"error": "not found"}), 404
    return jsonify(order)
