import pytest
from db.connection import get_connection
from db.schema import create_tables


@pytest.fixture
def conn():
    connection = get_connection(":memory:")
    create_tables(connection)
    yield connection
    connection.close()
