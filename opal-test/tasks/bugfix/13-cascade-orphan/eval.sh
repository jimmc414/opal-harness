#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

echo "=== Running all tests ==="
python -m pytest tests/ -v

echo "=== Verifying cascade behavior inline ==="
python -c "
from orgstore.models import Department, Team, Employee, Assignment
from orgstore.store import EntityStore
from orgstore.service import OrgService

ds, ts, es, asgn = EntityStore(), EntityStore(), EntityStore(), EntityStore()
ds.add(Department(name='Eng', id='d1'))
ds.add(Department(name='Sales', id='d2'))
ts.add(Team(name='Back', department_id='d1', id='t1'))
ts.add(Team(name='Out', department_id='d2', id='t2'))
es.add(Employee(name='Alice', team_id='t1', id='e1'))
es.add(Employee(name='Bob', team_id='t2', id='e2'))
asgn.add(Assignment(title='A1', employee_id='e1', id='a1'))
asgn.add(Assignment(title='A2', employee_id='e2', id='a2'))

svc = OrgService(ds, ts, es, asgn)
svc.delete_department('d1')

assert ds.count() == 1, f'Expected 1 dept, got {ds.count()}'
assert ts.count() == 1, f'Expected 1 team, got {ts.count()}'
assert es.count() == 1, f'Expected 1 employee, got {es.count()}'
assert asgn.count() == 1, f'Expected 1 assignment, got {asgn.count()}'
assert es.get('e1') is None, 'Employee e1 should be removed'
assert asgn.get('a1') is None, 'Assignment a1 should be removed'
assert es.get('e2') is not None, 'Employee e2 should remain'
assert asgn.get('a2') is not None, 'Assignment a2 should remain'
print('Inline cascade verification passed.')
"

echo "=== All checks passed ==="
