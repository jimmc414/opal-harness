#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

# 1. Existing tests still pass
check "Existing tests pass" python3 -m pytest tests/test_api.py -v

# 2. Migration guide file exists
check "docs/migration-guide.md exists" test -f docs/migration-guide.md

# 3. Guide has a title (heading)
check "Guide has a title heading" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read()
assert content.strip().startswith('#'), 'File should start with a markdown heading'
"

# 4. Guide has overview section
check "Guide has overview/introduction section" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().lower()
assert any(w in content for w in ['overview', 'introduction', 'summary']), 'Missing overview section'
"

# 5. Documents URL path change /items -> /products
check "Documents URL path change (/items to /products)" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read()
cl = content.lower()
assert '/items' in content and '/products' in content, 'Must mention both /items and /products paths'
assert 'product' in cl, 'Must mention products'
"

# 6. Documents request field renames (name->title, price->cost, category->type)
check "Documents field rename: name to title" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().lower()
found_name = 'name' in content and 'title' in content
assert found_name, 'Must document name->title rename'
"

check "Documents field rename: price to cost" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().lower()
found_price = 'price' in content and 'cost' in content
assert found_price, 'Must document price->cost rename'
"

check "Documents field rename: category to type" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().lower()
found_cat = 'category' in content and 'type' in content
assert found_cat, 'Must document category->type rename'
"

# 7. Documents response format changes (data wrapper -> product/products)
check "Documents response format change (data to product/products)" python3 -c "
import re
with open('docs/migration-guide.md') as f:
    content = f.read()
cl = content.lower()
has_data_key = '\"data\"' in content or \"'data'\" in content or 'data' in cl
has_product_key = '\"product\"' in content or \"'product'\" in content or '\"products\"' in content or \"'products'\" in content
assert has_data_key and has_product_key, 'Must document response wrapper change from data to product/products'
"

# 8. Documents HTTP method change (PUT -> PATCH)
check "Documents HTTP method change (PUT to PATCH)" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().upper()
assert 'PUT' in content and 'PATCH' in content, 'Must document PUT->PATCH change'
"

# 9. Documents error format change (string -> structured object)
check "Documents error format change (structured errors)" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().lower()
has_code = 'code' in content
has_message = 'message' in content
has_error_format = has_code and has_message
assert has_error_format, 'Must document structured error format with code and message fields'
"

# 10. Documents status code changes (400->422, 200->204)
check "Documents status code change 400 to 422" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read()
assert '400' in content and '422' in content, 'Must document 400->422 status code change'
"

check "Documents status code change 200 to 204 for delete" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read()
assert '204' in content, 'Must document 204 status code for delete'
"

# 11. Code examples for at least 2 operations (before/after)
check "Includes code examples (at least 2 code blocks)" python3 -c "
import re
with open('docs/migration-guide.md') as f:
    content = f.read()
code_blocks = re.findall(r'\x60\x60\x60', content)
assert len(code_blocks) >= 4, f'Expected at least 4 code fences (2 pairs), found {len(code_blocks)}'
"

# 12. Documents item_id -> product_id parameter rename (easy-to-miss)
check "Documents item_id to product_id parameter rename" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read()
assert 'item_id' in content and 'product_id' in content, 'Must mention both item_id and product_id parameter names'
"

# 13. Documents count -> total response field change
check "Documents count to total field change" python3 -c "
with open('docs/migration-guide.md') as f:
    content = f.read().lower()
assert 'count' in content and 'total' in content, 'Must document count->total rename'
"

echo ""
echo "=== RESULTS ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
TOTAL=$((PASS + FAIL))
echo "TOTAL: $TOTAL"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
