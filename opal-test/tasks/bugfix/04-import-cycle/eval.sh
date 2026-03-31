#!/usr/bin/env bash
set -euo pipefail

cd "$WORK_DIR"

# Criterion 1: Import models without error
python3 -c "from app import models; print('PASS: criterion 1 - models imports')"

# Criterion 2: Import validators without error
python3 -c "from app import validators; print('PASS: criterion 2 - validators imports')"

# Criterion 3: Import helpers without error
python3 -c "from app import helpers; print('PASS: criterion 3 - helpers imports')"

# Criterion 4: All existing tests pass
python3 -m pytest tests/ -x -q

# Criterion 5: Public API unchanged — all functions/classes importable from original modules
python3 -c "
import inspect

# models.py public API
from app.models import User, Order
u = User(name='Test', email='test@test.com')
assert hasattr(u, 'name'), 'User missing name attr'
assert hasattr(u, 'email'), 'User missing email attr'
o = Order(user=u, item='Widget', quantity=1, price_cents=999)
assert hasattr(o, 'user'), 'Order missing user attr'
assert hasattr(o, 'item'), 'Order missing item attr'

# validators.py public API
from app.validators import validate_email, validate_order
sig_ve = inspect.signature(validate_email)
assert 'email' in sig_ve.parameters, f'validate_email signature changed: {sig_ve}'
sig_vo = inspect.signature(validate_order)
assert 'order' in sig_vo.parameters, f'validate_order signature changed: {sig_vo}'

# helpers.py public API
from app.helpers import normalize_string, format_currency
sig_ns = inspect.signature(normalize_string)
assert 'value' in sig_ns.parameters, f'normalize_string signature changed: {sig_ns}'
sig_fc = inspect.signature(format_currency)
assert 'cents' in sig_fc.parameters, f'format_currency signature changed: {sig_fc}'

# Verify functions actually work
assert validate_email('test@example.com') is True
assert validate_email('not-an-email') is False
assert normalize_string('  Hello  ') == 'hello'
assert format_currency(1999) == '\$19.99'

print('PASS: criterion 5 - public API unchanged')
"

echo "ALL CRITERIA PASSED"
