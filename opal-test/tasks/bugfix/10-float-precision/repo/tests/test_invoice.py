"""Tests for billing.invoice -- precision tests with 50 items.

Expected values were computed with decimal.Decimal and are the
authoritative correct answers.
"""

import re

import pytest

from billing.invoice import Invoice
from billing.formatter import format_invoice


# ---- Correct values (computed via decimal.Decimal, ROUND_HALF_UP) --------
# Subtotal of all 50 items:        998.23
# Tax at 8.75 percent:              87.35
# Total (no discount):            1085.58
# 10 percent discount:              99.82
# Taxable after discount:          898.41
# Tax on discounted amount:         78.61
# Total (10 percent discount):    977.02
# --------------------------------------------------------------------------


# =====================================================================
# Single-item -- float error imperceptible, always passes
# =====================================================================

def test_single_item(empty_invoice):
    empty_invoice.add_item("Widget", 19.99, 2)
    assert empty_invoice.subtotal() == pytest.approx(39.98, abs=0.005)


# =====================================================================
# Few items -- float error negligible, passes
# =====================================================================

def test_few_items(small_invoice):
    expected_sub = 9.99 * 2 + 24.95 * 1 + 0.75 * 10  # 52.43
    assert small_invoice.subtotal() == pytest.approx(52.43, abs=0.005)


# =====================================================================
# Many items -- float errors compound, FAILS before fix
# =====================================================================

def test_many_items(large_invoice):
    """Subtotal of 50 items must be exactly 998.23 (within half a cent).

    Additionally, the returned value must already be rounded to cents.
    """
    sub = large_invoice.subtotal()
    assert round(sub, 2) == sub, (
        f"Subtotal must be rounded to cents; got {sub!r}"
    )
    assert sub == pytest.approx(998.23, abs=0.005), (
        f"Subtotal drifted -- expected 998.23, got {sub!r}."
    )


def test_tax_calculation(large_invoice):
    """Tax on 50-item invoice must match Decimal-computed 87.35.

    The tax function must return a value that, when rounded to 2 decimal
    places, equals 87.35. Raw float arithmetic produces a value that
    is not properly rounded. The returned value must already be rounded
    to cents (round(tax, 2) == tax).
    """
    tax = large_invoice.tax()
    # The returned value must be properly rounded to cents
    assert round(tax, 2) == tax, (
        f"Tax must be rounded to cents; got {tax!r}"
    )
    assert tax == pytest.approx(87.35, abs=0.005), (
        f"Tax should be 87.35 but got {tax:.4f}. "
        "Tax was likely computed on an unrounded subtotal."
    )


def test_discount_then_tax(large_invoice):
    """Total with 10 percent discount must match Decimal-computed 977.02."""
    total = large_invoice.total(discount_percent=10.0)
    assert round(total, 2) == total, (
        f"Total must be rounded to cents; got {total!r}"
    )
    assert total == pytest.approx(977.02, abs=0.005), (
        f"Total with 10 percent discount should be 977.02 but got {total:.4f}. "
        "Float errors compounded through discount and tax stages."
    )


# =====================================================================
# Formatting -- must always show exactly 2 decimal places
# =====================================================================

def test_format_two_decimal_places(large_invoice):
    """Every dollar amount in the formatted invoice must have exactly 2
    decimal places (e.g., '$19.90' not '$19.9' or '$19.900').
    """
    text = format_invoice(large_invoice, discount_percent=10.0)

    # Find all dollar amounts in the output
    dollar_amounts = re.findall(r"\$[\d,]+\.?\d*", text)
    assert len(dollar_amounts) > 0, "No dollar amounts found in formatted output"

    for amount in dollar_amounts:
        # Strip the leading dollar sign
        numeric = amount.lstrip("$")
        # Must have exactly 2 digits after the decimal point
        assert re.match(r"^\d+\.\d{2}$", numeric), (
            f"Amount {amount!r} does not have exactly 2 decimal places"
        )
