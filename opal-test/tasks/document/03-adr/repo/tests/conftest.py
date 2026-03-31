import pytest
import tempfile
import os
from app import create_app, get_db
from app.models import init_db


@pytest.fixture
def client():
    db_fd, db_path = tempfile.mkstemp(suffix='.db')
    app = create_app(db_path)
    app.config['TESTING'] = True

    with app.app_context():
        conn = get_db(app)
        init_db(conn)

    with app.test_client() as c:
        yield c

    os.close(db_fd)
    os.unlink(db_path)
