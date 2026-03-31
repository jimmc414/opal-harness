import json
from flask import Blueprint, jsonify, request
from app import get_db
from app.models import add_event, get_events
from app.processor import process_pending

bp = Blueprint('api', __name__)


@bp.route('/api/events', methods=['POST'])
def create_event():
    data = request.get_json()
    if not data or 'type' not in data or 'payload' not in data:
        return jsonify({"error": "type and payload required"}), 400
    conn = get_db()
    payload = data['payload']
    payload_str = json.dumps(payload) if not isinstance(payload, str) else payload
    eid = add_event(conn, data['type'], payload_str)
    return jsonify({"id": eid}), 201


@bp.route('/api/events')
def list_events():
    conn = get_db()
    events = get_events(conn)
    return jsonify(events)


@bp.route('/api/process', methods=['POST'])
def process():
    conn = get_db()
    results = process_pending(conn)
    return jsonify({"processed": len(results), "results": results})
