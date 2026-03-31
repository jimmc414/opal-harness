#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Running all tests ==="
python -m pytest tests/ -v

echo "=== Verifying round-trip inline ==="
python -c "
from pipeline.ingest import read_file
from pipeline.transform import normalize
from pipeline.export import write_output
import tempfile, os

with tempfile.TemporaryDirectory() as td:
    out = os.path.join(td, 'out.txt')
    lines = read_file('data/utf8_input.txt')
    transformed = normalize(lines)
    write_output(transformed, out)

    with open(out, encoding='utf-8') as f:
        result = f.read()

    assert 'café' in result, f'Expected cafe with accent in output, got: {result!r}'
    assert 'crème' in result, f'Expected creme with accent in output, got: {result!r}'
    assert 'résumé' in result, f'Expected resume with accents in output, got: {result!r}'
    print('UTF-8 round-trip verified.')

with tempfile.TemporaryDirectory() as td:
    out = os.path.join(td, 'out.txt')
    lines = read_file('data/latin1_input.txt')
    transformed = normalize(lines)
    write_output(transformed, out)

    with open(out, encoding='utf-8') as f:
        result = f.read()

    assert 'rené' in result, f'Expected rene with accent in output, got: {result!r}'
    assert 'straße' in result, f'Expected strasse with eszett in output, got: {result!r}'
    assert 'françois' in result, f'Expected francois with cedilla in output, got: {result!r}'
    print('Latin-1 round-trip verified.')
"

echo "=== All checks passed ==="
