#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# --- Parse compose file and check structure ---
python3 << 'PYEOF'
import sys, re, json

with open('docker-compose.yml') as f:
    content = f.read()

try:
    import yaml
    data = yaml.safe_load(content)
except ImportError:
    data = {'services': {}}
    current_service = None
    in_services = False
    in_env = False
    in_depends = False
    for line in content.split('\n'):
        stripped = line.rstrip()
        if stripped == 'services:':
            in_services = True
            continue
        if re.match(r'^networks:', stripped):
            data['networks'] = {}
            in_services = False
            continue
        if in_services:
            svc_match = re.match(r'^  (\w[\w-]*):$', stripped)
            if svc_match:
                current_service = svc_match.group(1)
                data['services'][current_service] = {}
                in_env = False
                in_depends = False
                continue
        if current_service and in_services:
            if re.match(r'^    environment:', stripped):
                in_env = True
                in_depends = False
                data['services'][current_service]['environment'] = []
                continue
            if re.match(r'^    depends_on:', stripped):
                in_depends = True
                in_env = False
                data['services'][current_service]['depends_on'] = []
                continue
            if re.match(r'^    \w', stripped) and not stripped.strip().startswith('-'):
                in_env = False
                in_depends = False
            if in_env and stripped.strip().startswith('-'):
                val = stripped.strip().lstrip('- ').strip()
                data['services'][current_service].setdefault('environment', []).append(val)
            if in_depends and stripped.strip().startswith('-'):
                val = stripped.strip().lstrip('- ').strip()
                data['services'][current_service].setdefault('depends_on', []).append(val)

results = {
    'has_networks': 'networks' in data,
    'has_depends_on': False,
    'service_names': sorted(data.get('services', {}).keys()),
}

for name, svc in data.get('services', {}).items():
    if isinstance(svc, dict) and 'depends_on' in svc:
        results['has_depends_on'] = True

with open('.eval_results.json', 'w') as f:
    json.dump(results, f)
PYEOF

# --- AC: Custom network defined ---
HAS_NETWORKS=$(python3 -c "import json; print(json.load(open('.eval_results.json'))['has_networks'])")
if [ "$HAS_NETWORKS" = "True" ]; then
    pass "custom network defined in docker-compose.yml"
else
    fail "no custom network defined in docker-compose.yml"
fi

# --- AC: Service dependencies declared ---
HAS_DEPENDS=$(python3 -c "import json; print(json.load(open('.eval_results.json'))['has_depends_on'])")
if [ "$HAS_DEPENDS" = "True" ]; then
    pass "service dependencies (depends_on) declared"
else
    fail "no depends_on found in docker-compose.yml"
fi

# --- AC: Service names consistent with config defaults ---
SERVICE_NAMES=$(python3 -c "import json; print(' '.join(json.load(open('.eval_results.json'))['service_names']))")

WEB_HOST=$(python3 << 'PYEOF'
import ast
with open('web/config.py') as f:
    tree = ast.parse(f.read())
for node in ast.walk(tree):
    if isinstance(node, ast.Assign):
        for t in node.targets:
            if isinstance(t, ast.Name) and t.id == 'API_HOST':
                if isinstance(node.value, ast.Call):
                    if len(node.value.args) >= 2:
                        val = ast.literal_eval(node.value.args[1])
                        from urllib.parse import urlparse
                        print(urlparse(val).hostname or '')
PYEOF
)

API_DB_HOST=$(python3 << 'PYEOF'
import ast
with open('api/config.py') as f:
    tree = ast.parse(f.read())
for node in ast.walk(tree):
    if isinstance(node, ast.Assign):
        for t in node.targets:
            if isinstance(t, ast.Name) and t.id == 'DATABASE_URL':
                if isinstance(node.value, ast.Call):
                    if len(node.value.args) >= 2:
                        val = ast.literal_eval(node.value.args[1])
                        parts = val.split('://')[1] if '://' in val else val
                        host = parts.split(':')[0].split('@')[-1]
                        print(host)
PYEOF
)

if echo "$SERVICE_NAMES" | tr ' ' '\n' | grep -qw "$WEB_HOST" 2>/dev/null; then
    pass "web/config.py API_HOST default ($WEB_HOST) matches a compose service"
else
    fail "web/config.py API_HOST default host ($WEB_HOST) does not match any compose service ($SERVICE_NAMES)"
fi

if echo "$SERVICE_NAMES" | tr ' ' '\n' | grep -qw "$API_DB_HOST" 2>/dev/null; then
    pass "api/config.py DATABASE_URL default host ($API_DB_HOST) matches a compose service"
else
    fail "api/config.py DATABASE_URL default host ($API_DB_HOST) does not match any compose service ($SERVICE_NAMES)"
fi

# --- AC: All services attached to the custom network ---
python3 -c "
import json
results = json.load(open('.eval_results.json'))
assert results['has_networks'], 'No networks section'
" && {
    python3 << 'PYEOF'
import sys, re, json

results = json.load(open('.eval_results.json'))

with open('docker-compose.yml') as f:
    content = f.read()

try:
    import yaml
    data = yaml.safe_load(content)
except ImportError:
    data = json.load(open('.eval_results.json'))
    data['services'] = {}
    # Re-parse with the manual parser from block 1
    current_service = None
    in_services = False
    in_networks_svc = False
    for line in content.split('\n'):
        stripped = line.rstrip()
        if stripped == 'services:':
            in_services = True
            continue
        if re.match(r'^networks:', stripped):
            in_services = False
            continue
        if in_services:
            svc_match = re.match(r'^  (\w[\w-]*):$', stripped)
            if svc_match:
                current_service = svc_match.group(1)
                data['services'][current_service] = {}
                in_networks_svc = False
                continue
        if current_service and in_services:
            if re.match(r'^    networks:', stripped):
                in_networks_svc = True
                data['services'][current_service]['networks'] = []
                continue
            if re.match(r'^    \w', stripped) and not stripped.strip().startswith('-'):
                in_networks_svc = False

services = data.get('services', {})
for name, svc in services.items():
    if not isinstance(svc, dict):
        continue
    has_net = 'networks' in svc
    if not has_net:
        # Also check via raw content for the service block
        pass
    if not has_net:
        print(f'Service {name} not attached to custom network', file=sys.stderr)
        sys.exit(1)
PYEOF
} && pass "all services attached to custom network" || fail "not all services attached to custom network"

# --- AC: Dependency direction correct (api depends on db, web depends on api) ---
python3 << 'PYEOF' && pass "dependency direction correct" || fail "dependency direction incorrect"
import sys, re, json

with open('docker-compose.yml') as f:
    content = f.read()

try:
    import yaml
    data = yaml.safe_load(content)
except ImportError:
    data = json.load(open('.eval_results.json'))
    data['services'] = {}
    current_service = None
    in_services = False
    in_depends = False
    for line in content.split('\n'):
        stripped = line.rstrip()
        if stripped == 'services:':
            in_services = True
            continue
        if re.match(r'^[a-z]', stripped) and ':' in stripped:
            in_services = False
            continue
        if in_services:
            svc_match = re.match(r'^  (\w[\w-]*):$', stripped)
            if svc_match:
                current_service = svc_match.group(1)
                data['services'][current_service] = {}
                in_depends = False
                continue
        if current_service and in_services:
            if re.match(r'^    depends_on:', stripped):
                in_depends = True
                data['services'][current_service]['depends_on'] = []
                continue
            if re.match(r'^    \w', stripped) and not stripped.strip().startswith('-'):
                in_depends = False
            if in_depends and stripped.strip().startswith('-'):
                val = stripped.strip().lstrip('- ').strip()
                data['services'][current_service].setdefault('depends_on', []).append(val)

services = data.get('services', {})
svc_names = set(services.keys())

# Find which service is the "api" (has DATABASE_URL)
# Find which service is the "web" (has API_URL)
# Find which service is the "db" (has postgres image or POSTGRES_DB)
api_svc = db_svc = web_svc = None
for name, svc in services.items():
    if not isinstance(svc, dict):
        continue
    img = str(svc.get('image', ''))
    env = svc.get('environment', [])
    env_strs = env if isinstance(env, list) else [f'{k}={v}' for k, v in env.items()]
    env_joined = ' '.join(str(e) for e in env_strs)
    if 'postgres' in img or 'POSTGRES_DB' in env_joined:
        db_svc = name
    if 'DATABASE_URL' in env_joined:
        api_svc = name
    if 'API_URL' in env_joined:
        web_svc = name

assert db_svc, f'No DB service found in {svc_names}'
assert api_svc, f'No API service found in {svc_names}'

# Check api depends on db
api_deps = services.get(api_svc, {}).get('depends_on', [])
if isinstance(api_deps, dict):
    api_deps = list(api_deps.keys())
assert db_svc in api_deps, f'{api_svc} does not depend on {db_svc}. deps={api_deps}'

# Check web depends on api (if web service exists)
if web_svc:
    web_deps = services.get(web_svc, {}).get('depends_on', [])
    if isinstance(web_deps, dict):
        web_deps = list(web_deps.keys())
    assert api_svc in web_deps, f'{web_svc} does not depend on {api_svc}. deps={web_deps}'
PYEOF

# --- AC: Env vars in compose reference correct service names ---
python3 << 'PYEOF' && pass "compose env vars reference valid service names" || fail "compose env vars reference non-existent service names"
import sys, re, json

results = json.load(open('.eval_results.json'))
svc_names = set(results['service_names'])

with open('docker-compose.yml') as f:
    content = f.read()

try:
    import yaml
    data = yaml.safe_load(content)
except ImportError:
    # Use results from block 1
    data = {'services': {}}
    current_service = None
    in_services = False
    in_env = False
    for line in content.split('\n'):
        stripped = line.rstrip()
        if stripped == 'services:':
            in_services = True
            continue
        if re.match(r'^[a-z]', stripped) and ':' in stripped and not in_services:
            continue
        if in_services:
            svc_match = re.match(r'^  (\w[\w-]*):$', stripped)
            if svc_match:
                current_service = svc_match.group(1)
                data['services'][current_service] = {}
                in_env = False
                continue
        if current_service and in_services:
            if re.match(r'^    environment:', stripped):
                in_env = True
                data['services'][current_service]['environment'] = []
                continue
            if re.match(r'^    \w', stripped) and not stripped.strip().startswith('-'):
                in_env = False
            if in_env and stripped.strip().startswith('-'):
                val = stripped.strip().lstrip('- ').strip()
                data['services'][current_service].setdefault('environment', []).append(val)

for name, svc in data.get('services', {}).items():
    if not isinstance(svc, dict):
        continue
    env = svc.get('environment', [])
    entries = env if isinstance(env, list) else [f'{k}={v}' for k, v in env.items()]
    for e in entries:
        if not isinstance(e, str):
            continue
        for pattern in [r'://(\w[\w-]*?):', r'://(\w[\w-]*?)/', r'://(\w[\w-]*?)$']:
            m = re.search(pattern, e)
            if m:
                ref = m.group(1)
                if ref not in svc_names:
                    print(f'MISMATCH: {name} env "{e}" references "{ref}" not in {svc_names}', file=sys.stderr)
                    sys.exit(1)
PYEOF

# --- AC: DATABASE_URL env var references correct postgres service (easy-to-miss) ---
python3 << 'PYEOF' && pass "DATABASE_URL references correct postgres service name" || fail "DATABASE_URL does not reference the postgres service name"
import sys, re

with open('docker-compose.yml') as f:
    content = f.read()

try:
    import yaml
    data = yaml.safe_load(content)
    services = data.get('services', {})
except ImportError:
    services = {}
    current_service = None
    in_services = False
    in_env = False
    for line in content.split('\n'):
        stripped = line.rstrip()
        if stripped == 'services:':
            in_services = True
            continue
        if in_services:
            svc_match = re.match(r'^  (\w[\w-]*):$', stripped)
            if svc_match:
                current_service = svc_match.group(1)
                services[current_service] = {}
                in_env = False
                continue
        if current_service and in_services:
            if re.match(r'^    environment:', stripped):
                in_env = True
                services[current_service]['environment'] = []
                continue
            if re.match(r'^    image:', stripped):
                services[current_service]['image'] = stripped.split(':', 1)[1].strip()
            if re.match(r'^    \w', stripped) and not stripped.strip().startswith('-'):
                in_env = False
            if in_env and stripped.strip().startswith('-'):
                val = stripped.strip().lstrip('- ').strip()
                services[current_service].setdefault('environment', []).append(val)

pg_service = None
for name, svc in services.items():
    if not isinstance(svc, dict):
        continue
    img = str(svc.get('image', ''))
    if 'postgres' in img:
        pg_service = name
        break
    env = svc.get('environment', [])
    entries = env if isinstance(env, list) else [f'{k}={v}' for k, v in (env.items() if isinstance(env, dict) else [])]
    for e in entries:
        if isinstance(e, str) and 'POSTGRES_DB' in e:
            pg_service = name
            break

if not pg_service:
    print('No postgres service found', file=sys.stderr)
    sys.exit(1)

found_match = False
for name, svc in services.items():
    if not isinstance(svc, dict):
        continue
    env = svc.get('environment', [])
    entries = env if isinstance(env, list) else [f'{k}={v}' for k, v in (env.items() if isinstance(env, dict) else [])]
    for e in entries:
        if isinstance(e, str) and 'DATABASE_URL' in e and pg_service in e:
            found_match = True

if not found_match:
    print(f'DATABASE_URL does not reference postgres service ({pg_service})', file=sys.stderr)
    sys.exit(1)
PYEOF

# --- Cleanup ---
rm -f .eval_results.json

# --- AC: Existing tests still pass ---
python3 -m pytest tests/ -q --tb=short 2>&1 && pass "existing tests pass" || fail "existing tests fail"

# --- Summary ---
echo ""
echo "=== RESULTS: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
