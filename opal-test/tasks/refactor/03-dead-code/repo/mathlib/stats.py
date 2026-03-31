from mathlib.core import add, deprecated_power
import statistics
import csv


def mean(values):
    if not values:
        raise ValueError("Empty list")
    total = add(values[0], sum(values[1:]))
    return total / len(values)


def median(values):
    if not values:
        raise ValueError("Empty list")
    sorted_values = sorted(values)
    n = len(sorted_values)
    mid = n // 2
    if n % 2 == 0:
        return (sorted_values[mid - 1] + sorted_values[mid]) / 2
    return sorted_values[mid]


def variance(values):
    m = mean(values)
    return sum((x - m) ** 2 for x in values) / len(values)


def correlation(x_values, y_values):
    pass
