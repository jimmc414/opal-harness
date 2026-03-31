import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


def test_web_config_loads():
    from web.config import API_HOST, TIMEOUT
    assert isinstance(API_HOST, str)
    assert TIMEOUT == 30


def test_api_config_loads():
    from api.config import DATABASE_URL, API_PORT
    assert isinstance(DATABASE_URL, str)
    assert API_PORT == 5000


def test_api_get_config():
    from api.app import get_config
    config = get_config()
    assert 'db_host' in config
    assert 'port' in config


def test_web_fetch_items():
    from web.app import fetch_items
    result = fetch_items()
    assert 'url' in result
    assert 'timeout' in result
