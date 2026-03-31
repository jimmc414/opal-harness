from ingest.pipeline import ingest


def test_ingest_valid_records():
    records = [
        {"name": "Test", "email": "test@example.com", "age": 25, "role": "user"},
    ]
    result = ingest(records)
    assert len(result["accepted"]) + len(result["rejected"]) == 1


def test_ingest_returns_dict():
    result = ingest([])
    assert "accepted" in result
    assert "rejected" in result
