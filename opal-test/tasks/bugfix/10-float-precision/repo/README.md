# Billing

A simple invoice-calculation library.

## Usage

```python
from billing.invoice import Invoice

inv = Invoice()
inv.add_item("Widget", price=19.99, quantity=3)
inv.add_item("Gadget", price=3.49, quantity=10)

print(inv.subtotal())
print(inv.tax(0.0875))
print(inv.total())
```

## Modules

| Module | Purpose |
|--------|---------|
| `billing.invoice` | `Invoice` class — add items, compute subtotal / tax / discount / total |
| `billing.formatter` | `format_invoice` — human-readable text output |
| `billing.constants` | Shared constants (TAX_RATE, DISCOUNT_THRESHOLD) |

## Running Tests

```bash
pytest tests/ -v
```
