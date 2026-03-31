from flask import Blueprint, jsonify, request
from app.models import ITEMS
from app.pagination import paginate_offset

bp = Blueprint('api', __name__)


@bp.route('/items')
def list_items():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    result = paginate_offset(ITEMS, page, per_page)
    return jsonify(result)
