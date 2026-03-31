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

# Run existing app tests
check "Existing app tests pass" python3 -m pytest tests/ -q --tb=short

# Check nginx.conf has SSL server block listening on 443
check "nginx.conf has listen 443 ssl" grep -qP 'listen\s+443\s+ssl' config/nginx.conf

# Check SSL certificate directive
check "nginx.conf has ssl_certificate directive" grep -qP 'ssl_certificate\s+\S+' config/nginx.conf

# Check SSL certificate key directive
check "nginx.conf has ssl_certificate_key directive" grep -qP 'ssl_certificate_key\s+\S+' config/nginx.conf

# Check HTTP-to-HTTPS redirect on port 80
check "Port 80 block redirects to HTTPS" grep -qP 'return\s+301\s+https' config/nginx.conf

# Check HTTPS block proxies to Flask app
check "HTTPS block proxies to 127.0.0.1:5000" python3 -c "
import re
with open('config/nginx.conf') as f:
    content = f.read()
# Find the 443 server block and check it has proxy_pass
blocks = re.split(r'(?=server\s*\{)', content)
found = False
for block in blocks:
    if re.search(r'listen\s+443\s+ssl', block) and re.search(r'proxy_pass\s+http://127\.0\.0\.1:5000', block):
        found = True
        break
assert found, 'HTTPS block must proxy to 127.0.0.1:5000'
"

# Easy-to-miss: HTTPS block must have proxy_set_header Host
check "HTTPS block has proxy_set_header Host" python3 -c "
import re
with open('config/nginx.conf') as f:
    content = f.read()
blocks = re.split(r'(?=server\s*\{)', content)
found = False
for block in blocks:
    if re.search(r'listen\s+443\s+ssl', block) and re.search(r'proxy_set_header\s+Host\s+', block):
        found = True
        break
assert found, 'HTTPS block must have proxy_set_header Host'
"

# Easy-to-miss: HTTPS block must have proxy_set_header X-Real-IP
check "HTTPS block has proxy_set_header X-Real-IP" python3 -c "
import re
with open('config/nginx.conf') as f:
    content = f.read()
blocks = re.split(r'(?=server\s*\{)', content)
found = False
for block in blocks:
    if re.search(r'listen\s+443\s+ssl', block) and re.search(r'proxy_set_header\s+X-Real-IP\s+', block):
        found = True
        break
assert found, 'HTTPS block must have proxy_set_header X-Real-IP'
"

# Check deploy/check_config.py confirms all checks pass
check "check_config.py validates all True" python3 -c "
import subprocess, sys
result = subprocess.run([sys.executable, 'deploy/check_config.py', 'config/nginx.conf'], capture_output=True, text=True)
output = result.stdout
for line in output.strip().split('\n'):
    key, val = line.split(': ')
    assert val == 'True', f'{key} is not True'
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
