import os
from etl.extract import extract
from etl.transform import transform
from etl.load import TargetStore, load


def test_extract():
    path = os.path.join(os.path.dirname(__file__), '..', 'data', 'source.json')
    records = extract(path)
    assert len(records) == 8


def test_transform_valid():
    records = [{"id": 1, "name": "Test", "price": 9.99, "quantity": 5, "active": True}]
    result = transform(records)
    assert len(result) == 1
    assert result[0]["id"] == 1


def test_load():
    store = TargetStore()
    records = [{"id": 1, "name": "Test"}]
    count = load(store, records)
    assert count == 1
    assert len(store.get_all()) == 1
