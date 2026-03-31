from flask import Blueprint, jsonify, request
from models.items import get_items, get_item, add_item, update_item, remove_item

bp = Blueprint('v2', __name__)


@bp.route('/products')
def list_products():
    """List all products with pagination metadata."""
    items = get_items()
    return jsonify({"products": items, "total": len(items), "page": 1})


@bp.route('/products/<int:product_id>')
def show_product(product_id):
    """Get a single product by ID."""
    item = get_item(product_id)
    if not item:
        return jsonify({"error": {"code": "NOT_FOUND", "message": "Product not found"}}), 404
    return jsonify({"product": item})


@bp.route('/products', methods=['POST'])
def create_product():
    """Create a new product."""
    data = request.get_json()
    if not data or 'title' not in data:
        return jsonify({"error": {"code": "VALIDATION_ERROR", "message": "title required"}}), 422
    item = add_item(data['title'], data.get('cost', 0), data.get('type', 'general'))
    return jsonify({"product": item}), 201


@bp.route('/products/<int:product_id>', methods=['PATCH'])
def update_product(product_id):
    """Partially update a product."""
    data = request.get_json()
    mapped = {}
    if 'title' in data:
        mapped['name'] = data['title']
    if 'cost' in data:
        mapped['price'] = data['cost']
    if 'type' in data:
        mapped['category'] = data['type']
    item = update_item(product_id, **mapped)
    if not item:
        return jsonify({"error": {"code": "NOT_FOUND", "message": "Product not found"}}), 404
    return jsonify({"product": item})


@bp.route('/products/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    item = remove_item(product_id)
    if not item:
        return jsonify({"error": {"code": "NOT_FOUND", "message": "Product not found"}}), 404
    return jsonify({}), 204
