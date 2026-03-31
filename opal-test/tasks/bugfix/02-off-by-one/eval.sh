#!/usr/bin/env bash
set -euo pipefail

cd "$WORK_DIR"

# Criterion 1: page=1 returns the first per_page items
python3 -c "
from paginator.core import paginate
items = list(range(1, 26))  # [1..25]
result = paginate(items, page=1, per_page=10)
assert result.items == list(range(1, 11)), (
    f'page=1 should return [1..10], got {result.items}'
)
print('PASS: criterion 1 - page=1 returns first per_page items')
"

# Criterion 2: No items duplicated or skipped across consecutive pages
python3 -c "
from paginator.core import paginate, total_pages
items = list(range(1, 26))  # 25 items
tp = total_pages(items, per_page=10)
all_items = []
for p in range(1, tp + 1):
    result = paginate(items, page=p, per_page=10)
    all_items.extend(result.items)
assert all_items == items, (
    f'Union of all pages should equal original list.\n'
    f'Expected {items}\nGot      {all_items}'
)
print('PASS: criterion 2 - no duplicates or gaps')
"

# Criterion 3: All existing tests pass
python3 -m pytest tests/ -x -q

# Criterion 4: page=0 or negative page raises ValueError
python3 -c "
from paginator.core import paginate
items = list(range(10))

for bad_page in [0, -1, -100]:
    try:
        paginate(items, page=bad_page)
        raise AssertionError(f'paginate(items, page={bad_page}) should raise ValueError')
    except ValueError:
        pass  # expected

print('PASS: criterion 4 - ValueError on page<=0')
"

echo "ALL CRITERIA PASSED"
