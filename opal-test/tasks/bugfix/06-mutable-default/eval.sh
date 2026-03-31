#!/usr/bin/env bash
set -e
cd "$WORK_DIR"

echo "=== bugfix-06-mutable-default eval ==="

# Criterion 1: create_task tags don't leak between calls
python -c "
from taskqueue.tasks import create_task

# Use default, then mutate the returned tags, then check a new default call
t1 = create_task('a')
t1['tags'].append('leaked')
t2 = create_task('b')
assert t2['tags'] == [], f'Tags leaked from t1 to t2: {t2[\"tags\"]}'

# Also test with explicit tags followed by default
t3 = create_task('c', tags=['x'])
t4 = create_task('d')
assert t4['tags'] == [], f'Tags leaked from t3 to t4: {t4[\"tags\"]}'
print('PASS: create_task tags isolation')
"

# Criterion 2: create_batch metadata doesn't leak between calls
python -c "
from taskqueue.tasks import create_batch

# Use default, then mutate the returned metadata, then check a new default call
b1 = create_batch(['a'])
b1['metadata']['leaked'] = 'yes'
b2 = create_batch(['b'])
assert b2['metadata'] == {}, f'Metadata leaked from b1 to b2: {b2[\"metadata\"]}'

# Also test with explicit metadata followed by default
b3 = create_batch(['c'], metadata={'k': 'v'})
b4 = create_batch(['d'])
assert b4['metadata'] == {}, f'Metadata leaked from b3 to b4: {b4[\"metadata\"]}'
print('PASS: create_batch metadata isolation')
"

# Criterion 3: All existing tests pass
python -m pytest tests/ -v --tb=short

# Criterion 4: Defensive copy — caller mutation doesn't affect task
python -c "
from taskqueue.tasks import create_task, create_batch

# Tags: caller mutation must not affect task
my_tags = ['web', 'api']
task = create_task('svc', tags=my_tags)
my_tags.append('extra')
assert task['tags'] == ['web', 'api'], (
    f'Caller tag mutation affected task: {task[\"tags\"]}'
)

# Tags: task mutation must not affect caller
task['tags'].append('internal')
assert my_tags == ['web', 'api', 'extra'], (
    f'Task tag mutation affected caller: {my_tags}'
)

# Metadata: caller mutation must not affect batch
my_meta = {'version': '1.0'}
batch = create_batch(['svc'], metadata=my_meta)
my_meta['added'] = 'later'
assert batch['metadata'] == {'version': '1.0'}, (
    f'Caller meta mutation affected batch: {batch[\"metadata\"]}'
)

print('PASS: Defensive copy verified for tags and metadata')
"

echo ""
echo "=== ALL CRITERIA PASSED ==="
