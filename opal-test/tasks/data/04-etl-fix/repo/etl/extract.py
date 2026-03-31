import json


def extract(filepath):
    with open(filepath) as f:
        return json.load(f)
