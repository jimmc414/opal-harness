from cleaner.loader import load_csv
import os


def test_load_csv():
    path = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw_sales.csv')
    rows = load_csv(path)
    assert len(rows) == 8
    assert rows[0]['customer'] == 'Alice'


def test_csv_has_headers():
    path = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw_sales.csv')
    rows = load_csv(path)
    assert 'id' in rows[0]
    assert 'date' in rows[0]
    assert 'amount' in rows[0]
