import pytest
from api import create_app
from models.items import reset


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    reset()
    with app.test_client() as c:
        yield c
