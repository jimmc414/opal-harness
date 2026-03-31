import pytest
from app import create_app
from app import models


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    models.reset()
    with app.test_client() as client:
        yield client
