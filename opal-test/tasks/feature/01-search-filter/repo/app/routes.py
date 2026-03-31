from flask import Blueprint, jsonify
from app.models import ITEMS

bp = Blueprint('items', __name__)


@bp.route('/items')
def list_items():
    return jsonify(ITEMS)
