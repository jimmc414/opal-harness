import pytest
from app import create_app
from app.models import ITEMS


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


@pytest.fixture(autouse=True)
def reset_items():
    original = ITEMS.copy()
    yield
    ITEMS.clear()
    ITEMS.extend(original)
