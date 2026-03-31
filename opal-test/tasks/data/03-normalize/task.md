## Source

Synthetic database normalization task. A legacy system stores order data in a single denormalized table with repeated customer information. The data needs to be split into properly normalized tables.

## Problem

The `database/setup.py` module creates a flat `orders` table where customer data (name, email, phone) is repeated on every order row. The `database/normalize.py` module has a stub `normalize()` function that needs to split this into separate `customers`, `products`, and normalized `orders` tables while preserving all data and relationships.

## Acceptance Criteria

- `normalize(conn)` creates `customers`, `products`, and normalized `orders` tables
- `customers` table has unique entries: 4 customers (Alice Smith, Bob Jones, Carol White, Dave Brown)
- `products` table has unique entries: 3 products (Widget, Gadget, Doohickey)
- Normalized `orders` table references `customer_id` and `product_id` via foreign keys
- All 7 original orders are preserved in the normalized structure
- Customer deduplication uses email as the unique key
- Bob Jones has phone number None in order 3 but 555-0202 in order 6; the customer record must store the non-null phone (555-0202)
- Existing tests still pass (flat orders table must remain queryable)

## Constraints

- Do not modify `database/setup.py`
- Do not add external dependencies beyond the Python standard library
- The original flat `orders` table must not be dropped (existing queries depend on it)
- Preserve the function signature of `normalize(conn)`
