from reports.formatters import format_text, format_json


def test_format_text(sample_report):
    result = format_text(sample_report)
    assert "Sales Report" in result
    assert "Alice" in result
    assert "2300" in result


def test_format_json(sample_report):
    result = format_json(sample_report)
    import json
    data = json.loads(result)
    assert data["title"] == "Sales Report"
    assert len(data["rows"]) == 3
