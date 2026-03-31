# Database Schema Migration

Migrate data from v1 schema to v2 schema in SQLite.

## Structure

- `db/v1_schema.py` - Creates v1 tables and seeds test data
- `db/v2_schema.py` - Creates v2 target schema (empty tables)
- `db/migrate.py` - Migration function to implement

## Schema Changes

### v1 Tables
- `users` (user_id, first_name, last_name, email_addr, signup_date, is_active, user_type)
- `purchases` (purchase_id, user_id, item_name, price_cents, purchased_at)

### v2 Tables
- `accounts` (id, full_name, email, created_at, active, tier)
- `transactions` (id, account_id, description, amount_dollars, transaction_date)

## Running Tests

```bash
python3 -m pytest tests/ -v
```
