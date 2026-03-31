from flask import Blueprint, jsonify, request

bp = Blueprint('api', __name__)

ITEMS = [{"id": i, "name": f"Item {i}"} for i in range(1, 51)]


@bp.route('/items')
def list_items():
    page = request.args.get('page', 1, type=int)
    page_size = 20
    start = (page - 1) * page_size
    end = start + page_size
    return jsonify({
        "items": ITEMS[start:end],
        "page": page,
        "page_size": page_size,
        "total": len(ITEMS),
    })
