import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import pytest
from services.logger import logger
from services.cache import cache
from services.mailer import mailer


@pytest.fixture(autouse=True)
def clean_state():
    logger.clear()
    cache.clear()
    mailer.clear()
    yield
    logger.clear()
    cache.clear()
    mailer.clear()
