from ingest.schema import validate_record


def ingest(records):
    results = {"accepted": [], "rejected": []}
    for record in records:
        errors = validate_record(record)
        if errors:
            results["rejected"].append({"record": record, "errors": errors})
        else:
            results["accepted"].append(record)
    return results
