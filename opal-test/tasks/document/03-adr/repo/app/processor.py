import json
from app.models import get_events, mark_processed


def process_pending(conn):
    events = get_events(conn, processed=0)
    results = []
    for event in events:
        result = handle_event(event)
        mark_processed(conn, event['id'])
        results.append(result)
    return results


def handle_event(event):
    payload = (
        json.loads(event['payload'])
        if isinstance(event['payload'], str)
        else event['payload']
    )
    return {
        "event_id": event['id'],
        "type": event['type'],
        "status": "processed",
        "data": payload,
    }
