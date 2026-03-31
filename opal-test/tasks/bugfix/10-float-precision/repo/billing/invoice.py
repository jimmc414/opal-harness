"""Invoice calculation module."""

from billing.constants import TAX_RATE, DISCOUNT_THRESHOLD


class Invoice:
    """Accumulates line items and computes totals."""

    def __init__(self):
        self._items: list[dict] = []

    # ------------------------------------------------------------------
    # Mutators
    # ------------------------------------------------------------------

    def add_item(self, name: str, price: float, quantity: int = 1) -> None:
        """Add a line item."""
        self._items.append({
            "name": name,
            "price": price,
            "quantity": quantity,
        })

    # ------------------------------------------------------------------
    # Computed values
    # ------------------------------------------------------------------

    def subtotal(self) -> float:
        """Sum of (price * quantity) for every line item."""
        total = 0.0
        for item in self._items:
            total += item["price"] * item["quantity"]
        return total

    def tax(self, rate: float | None = None) -> float:
        """Tax amount computed on the subtotal."""
        r = rate if rate is not None else TAX_RATE
        return self.subtotal() * r

    def discount(self, percent: float) -> float:
        """Discount amount (applied before tax)."""
        sub = self.subtotal()
        if sub >= DISCOUNT_THRESHOLD:
            return sub * (percent / 100.0)
        return 0.0

    def total(self, discount_percent: float = 0.0, tax_rate: float | None = None) -> float:
        """Final total: (subtotal - discount) + tax.

        Tax is computed on the discounted amount.
        """
        sub = self.subtotal()
        disc = self.discount(discount_percent)
        taxable = sub - disc
        r = tax_rate if tax_rate is not None else TAX_RATE
        t = taxable * r
        return taxable + t
