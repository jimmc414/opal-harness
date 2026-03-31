from flask import Blueprint, jsonify

bp = Blueprint('api', __name__)


@bp.route('/api/config')
def show_config():
    from flask import current_app
    return jsonify({
        "debug": current_app.config.get('DEBUG'),
        "log_level": current_app.config.get('LOG_LEVEL'),
    })


@bp.route('/api/items')
def list_items():
    from app.models import ITEMS
    return jsonify(ITEMS)
