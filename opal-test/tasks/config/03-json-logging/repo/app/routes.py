import logging
from flask import Blueprint, jsonify, request

logger = logging.getLogger(__name__)

bp = Blueprint('api', __name__)


@bp.route('/api/items')
def list_items():
    logger.info("Listing items")
    from app.models import ITEMS
    return jsonify(ITEMS)


@bp.route('/api/items', methods=['POST'])
def create_item():
    data = request.get_json()
    logger.info(f"Creating item: {data}")
    if not data or 'name' not in data:
        logger.warning("Missing name field")
        return jsonify({"error": "name required"}), 400
    from app.models import ITEMS
    item = {"id": len(ITEMS) + 1, "name": data["name"]}
    ITEMS.append(item)
    return jsonify(item), 201
