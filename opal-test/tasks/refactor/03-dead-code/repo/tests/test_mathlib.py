from mathlib import add, subtract, multiply, divide, mean, median


def test_add():
    assert add(2, 3) == 5


def test_subtract():
    assert subtract(5, 3) == 2


def test_multiply():
    assert multiply(4, 3) == 12


def test_divide():
    assert divide(10, 2) == 5.0


def test_divide_by_zero():
    import pytest
    with pytest.raises(ValueError):
        divide(1, 0)


def test_mean():
    assert mean([1, 2, 3, 4, 5]) == 3.0


def test_median():
    assert median([1, 2, 3, 4, 5]) == 3
    assert median([1, 2, 3, 4]) == 2.5
