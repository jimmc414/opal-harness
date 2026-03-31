import pytest
from reports.models import Report


@pytest.fixture
def sample_report():
    return Report(
        title="Sales Report",
        columns=["name", "amount", "region"],
        rows=[
            {"name": "Alice", "amount": 1500, "region": "North"},
            {"name": "Bob", "amount": 2300, "region": "South"},
            {"name": "Carol", "amount": 1800, "region": "East"},
        ]
    )


@pytest.fixture
def report_with_special_chars():
    return Report(
        title="Special Report",
        columns=["name", "description", "value"],
        rows=[
            {"name": "Item A", "description": "Contains, commas", "value": 100},
            {"name": 'Item "B"', "description": "Has quotes", "value": 200},
            {"name": "Item C", "description": "Normal item", "value": 300},
        ]
    )
