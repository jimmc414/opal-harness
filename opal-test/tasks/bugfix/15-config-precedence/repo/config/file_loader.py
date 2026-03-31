import json


def load_from_file(filepath):
    with open(filepath) as f:
        return json.load(f)
