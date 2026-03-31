import os
import pytest


@pytest.fixture
def data_dir():
    return os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")


@pytest.fixture
def utf8_path(data_dir):
    return os.path.join(data_dir, "utf8_input.txt")


@pytest.fixture
def latin1_path(data_dir):
    return os.path.join(data_dir, "latin1_input.txt")


@pytest.fixture
def tmp_output(tmp_path):
    return os.path.join(str(tmp_path), "output.txt")
