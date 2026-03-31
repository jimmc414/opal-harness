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

# Run existing tests
check "Existing API tests pass" python3 -m pytest tests/ -q --tb=short

# Check spec file exists (YAML or JSON)
check "OpenAPI spec file exists in docs/" python3 -c "
import os
yaml_path = os.path.join('docs', 'openapi.yaml')
yml_path = os.path.join('docs', 'openapi.yml')
json_path = os.path.join('docs', 'openapi.json')
assert os.path.isfile(yaml_path) or os.path.isfile(yml_path) or os.path.isfile(json_path), \
    'No openapi.yaml/.yml/.json found in docs/'
"

# Load and validate spec structure
check "Spec has openapi 3.0.x version, info, and paths" python3 -c "
import json, os

spec = None
for fname in ['docs/openapi.yaml', 'docs/openapi.yml', 'docs/openapi.json']:
    if os.path.isfile(fname):
        with open(fname) as f:
            content = f.read()
        if fname.endswith('.json'):
            spec = json.loads(content)
        else:
            try:
                import yaml
                spec = yaml.safe_load(content)
            except ImportError:
                # Fallback: try json in case it is actually json with yaml extension
                spec = json.loads(content)
        break

assert spec is not None, 'Could not load spec file'
version = str(spec.get('openapi', ''))
assert version.startswith('3.0'), f'Expected openapi 3.0.x, got {version}'
assert 'info' in spec, 'Missing info section'
assert 'paths' in spec, 'Missing paths section'
"

# Check all 5 endpoints are documented
check "All 5 endpoints documented" python3 -c "
import json, os

spec = None
for fname in ['docs/openapi.yaml', 'docs/openapi.yml', 'docs/openapi.json']:
    if os.path.isfile(fname):
        with open(fname) as f:
            content = f.read()
        if fname.endswith('.json'):
            spec = json.loads(content)
        else:
            try:
                import yaml
                spec = yaml.safe_load(content)
            except ImportError:
                spec = json.loads(content)
        break

paths = spec.get('paths', {})

# Normalize path keys - handle both {item_id} and {id} etc.
items_path = paths.get('/api/items', {})
item_path = None
for p in paths:
    if '/api/items/' in p and '{' in p:
        item_path = paths[p]
        break

assert 'get' in items_path, 'Missing GET /api/items'
assert 'post' in items_path, 'Missing POST /api/items'
assert item_path is not None, 'Missing /api/items/{item_id} path'
assert 'get' in item_path, 'Missing GET /api/items/{item_id}'
assert 'put' in item_path, 'Missing PUT /api/items/{item_id}'
assert 'delete' in item_path, 'Missing DELETE /api/items/{item_id}'
"

# Check endpoints have descriptions and response codes
check "Endpoints have descriptions and response codes" python3 -c "
import json, os

spec = None
for fname in ['docs/openapi.yaml', 'docs/openapi.yml', 'docs/openapi.json']:
    if os.path.isfile(fname):
        with open(fname) as f:
            content = f.read()
        if fname.endswith('.json'):
            spec = json.loads(content)
        else:
            try:
                import yaml
                spec = yaml.safe_load(content)
            except ImportError:
                spec = json.loads(content)
        break

paths = spec.get('paths', {})
for path, methods in paths.items():
    for method, details in methods.items():
        if method in ('get', 'post', 'put', 'delete'):
            desc = details.get('description') or details.get('summary')
            assert desc, f'{method.upper()} {path} has no description/summary'
            assert 'responses' in details, f'{method.upper()} {path} has no responses'
            codes = set(str(c) for c in details['responses'].keys())
            has_2xx = any(c.startswith('2') for c in codes)
            assert has_2xx, f'{method.upper()} {path} has no 2xx response code. Codes: {codes}'
            if method in ('post', 'put', 'delete'):
                has_4xx = any(c.startswith('4') for c in codes)
                assert has_4xx, f'{method.upper()} {path} has no 4xx response code. Codes: {codes}'
"

# Check POST documents request body schema with name, price, category
check "POST /api/items documents request body with name, price, category" python3 -c "
import json, os

spec = None
for fname in ['docs/openapi.yaml', 'docs/openapi.yml', 'docs/openapi.json']:
    if os.path.isfile(fname):
        with open(fname) as f:
            content = f.read()
        if fname.endswith('.json'):
            spec = json.loads(content)
        else:
            try:
                import yaml
                spec = yaml.safe_load(content)
            except ImportError:
                spec = json.loads(content)
        break

post_op = spec['paths']['/api/items']['post']
rb = post_op.get('requestBody', {})
assert rb, 'POST /api/items missing requestBody'

# Navigate to schema - handle inline or ref
content_types = rb.get('content', {})
schema = None
for ct in content_types.values():
    schema = ct.get('schema', {})
    break

# Handle \$ref to components
if '\$ref' in (schema or {}):
    ref_path = schema['\$ref'].split('/')
    obj = spec
    for part in ref_path:
        if part == '#':
            continue
        obj = obj[part]
    schema = obj

props = schema.get('properties', {})
assert 'name' in props, 'Missing name in request body schema'
assert 'price' in props, 'Missing price in request body schema'
assert 'category' in props, 'Missing category in request body schema'
"

# Easy-to-miss: path parameter item_id documented with type integer
check "Path parameter item_id has type integer" python3 -c "
import json, os

spec = None
for fname in ['docs/openapi.yaml', 'docs/openapi.yml', 'docs/openapi.json']:
    if os.path.isfile(fname):
        with open(fname) as f:
            content = f.read()
        if fname.endswith('.json'):
            spec = json.loads(content)
        else:
            try:
                import yaml
                spec = yaml.safe_load(content)
            except ImportError:
                spec = json.loads(content)
        break

paths = spec.get('paths', {})
found_int_param = False
for path, methods in paths.items():
    if '{' not in path:
        continue
    # Check path-level parameters
    params = methods.get('parameters', [])
    # Also check method-level parameters
    for method_name, method_details in methods.items():
        if isinstance(method_details, dict) and 'parameters' in method_details:
            params.extend(method_details['parameters'])
    for param in params:
        if param.get('in') == 'path':
            schema = param.get('schema', {})
            param_type = schema.get('type', param.get('type', ''))
            if param_type == 'integer':
                found_int_param = True
                break
    if found_int_param:
        break

assert found_int_param, 'No path parameter with type integer found for item_id'
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
