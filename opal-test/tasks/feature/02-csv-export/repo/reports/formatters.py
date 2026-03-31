import json


def format_text(report):
    lines = [report.title, "=" * len(report.title), ""]
    for row in report.rows:
        parts = [f"{col}: {row.get(col, '')}" for col in report.columns]
        lines.append(" | ".join(parts))
    return "\n".join(lines)


def format_json(report):
    return json.dumps({
        "title": report.title,
        "columns": report.columns,
        "rows": report.rows,
    }, indent=2)
