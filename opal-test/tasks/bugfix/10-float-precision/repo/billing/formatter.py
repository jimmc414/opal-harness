"""Human-readable invoice formatting.

NOTE: The formatting logic itself is correct, but it relies on the
caller's values.  This module must produce exactly two decimal places
for every dollar amount (e.g., "$19.90" NOT "$19.9").
"""

from billing.invoice import Invoice


def format_invoice(invoice: Invoice, discount_percent: float = 0.0) -> str:
    """Return a multi-line text representation of *invoice*."""
    lines: list[str] = []
    lines.append("=" * 50)
    lines.append("INVOICE")
    lines.append("=" * 50)

    for item in invoice._items:
        line_total = item["price"] * item["quantity"]
        lines.append(
            f"  {item['name']:<30s} "
            f"{item['quantity']:>3d} x ${item['price']:.2f} = ${line_total:.2f}"
        )

    lines.append("-" * 50)
    sub = invoice.subtotal()
    lines.append(f"  {'Subtotal':<36s} ${sub:.2f}")

    disc = invoice.discount(discount_percent)
    if disc > 0:
        lines.append(f"  {'Discount':<36s} -${disc:.2f}")

    taxable = sub - disc
    tax = invoice.tax()
    lines.append(f"  {'Tax':<36s} ${tax:.2f}")

    total = invoice.total(discount_percent=discount_percent)
    lines.append("=" * 50)
    lines.append(f"  {'TOTAL':<36s} ${total:.2f}")
    lines.append("=" * 50)

    return "\n".join(lines)
