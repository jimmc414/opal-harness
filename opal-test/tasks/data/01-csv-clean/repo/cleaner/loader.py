import csv


def load_csv(filepath):
    with open(filepath) as f:
        reader = csv.DictReader(f)
        return list(reader)
