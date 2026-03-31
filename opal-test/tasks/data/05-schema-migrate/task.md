## Source

Synthetic SQLite schema migration between incompatible versions.

## Problem

A SQLite database uses a v1 schema with `users` and `purchases` tables. A v2 schema has been defined with `accounts` and `transactions` tables that have incompatible changes: column renames, type conversions, computed columns, and value mappings. The `migrate_v1_to_v2()` function in `db/migrate.py` is a stub that needs to be implemented to transform all v1 data into the v2 schema.

Key changes from v1 to v2:
- `users` table becomes `accounts` with column renames and value mappings
- `purchases` table becomes `transactions` with price conversion from cents to dollars
- `first_name` and `last_name` must be concatenated into `full_name`
- `user_type` values must be mapped: `'free'` becomes `'basic'`, `'premium'` stays `'premium'`

## Acceptance Criteria

- `migrate_v1_to_v2(conn)` populates the v2 `accounts` table from v1 `users`
- `accounts.full_name` is `"FirstName LastName"` (concatenated with a single space)
- `accounts.email` comes from `email_addr`
- `accounts.created_at` comes from `signup_date`
- `accounts.tier` maps `'free'` to `'basic'` and `'premium'` to `'premium'`
- `accounts` has 4 rows (all users migrated)
- `transactions` table is populated from `purchases` with 6 rows
- `transactions.amount_dollars` equals `price_cents / 100.0` (e.g., 4999 becomes 49.99)
- `transactions.description` comes from `item_name`
- `transactions.transaction_date` comes from `purchased_at`
- Foreign key integrity: all `account_id` values in transactions reference valid accounts
- `users.is_active` maps to `accounts.active` and inactive status is preserved (Carol is inactive with `active=0`)
- Existing tests still pass

## Constraints

- Do not modify `db/v1_schema.py` or `db/v2_schema.py`
- The v2 tables are created before `migrate_v1_to_v2()` is called -- the function only needs to insert data
- Use only the Python standard library (sqlite3 is available)
- The migration function receives a single connection that has both v1 and v2 tables
