"""Shared fixtures for billing tests."""

import json
from pathlib import Path

import pytest

from billing.invoice import Invoice


DATA_DIR = Path(__file__).resolve().parent.parent / "data"


@pytest.fixture
def empty_invoice():
    return Invoice()


@pytest.fixture
def small_invoice():
    """Invoice with 3 items — float error too small to notice."""
    inv = Invoice()
    inv.add_item("Widget", 9.99, 2)
    inv.add_item("Gadget", 24.95, 1)
    inv.add_item("Bolt", 0.75, 10)
    return inv


@pytest.fixture
def large_invoice():
    """Invoice with items loaded from data/items.json."""
    items_file = DATA_DIR / "items.json"
    items = json.loads(items_file.read_text())
    inv = Invoice()
    for item in items:
        inv.add_item(item["name"], item["price"], item["quantity"])
    return inv
