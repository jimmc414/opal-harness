import os
import sys
import json
import math


def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    return a * b


def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b


def _internal_log(msg):
    print(f"[DEBUG] {msg}")


def deprecated_power(base, exp):
    _internal_log(f"Computing {base}^{exp}")
    return math.pow(base, exp)


def experimental_factorial(n):
    if n < 0:
        raise ValueError("Negative factorial")
    if n <= 1:
        return 1
    return n * experimental_factorial(n - 1)
