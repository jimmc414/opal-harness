# Task

## Source
Synthetic: designed to test repair, mid-check

## Problem
Invoices with many line items (50+) show a final total that is off by several cents compared to the expected amount. Subtotals, tax, and discount calculations all drift slightly from correct values as the number of items grows.

## Acceptance Criteria
- [ ] Invoice total for the 50 items in `data/items.json` matches the expected value to the cent (within $0.005).
- [ ] Tax calculation is accurate -- computed on a properly rounded subtotal.
- [ ] All existing tests pass (`pytest tests/`).
- [ ] `format_invoice` must still display exactly 2 decimal places for every dollar amount (e.g., `"$19.90"` not `"$19.9"`).

## Constraints
- Do not break existing tests
- Max cycles: 15
