# Task: Cascade Delete Leaves Orphaned Records

## Source
Synthetic: designed to test dead-ends, replan, checkpoint, multi-file

## Problem

The OrgStore application manages departments, teams, employees, and assignments
in an in-memory store. When a department is deleted via `delete_department()`,
orphaned records remain in the store. Specifically:

- Employees that belonged to teams within the deleted department are still
  present in the employee store after the department is removed.
- Assignments that were linked to those employees also remain in the
  assignment store after the department is removed.

This means downstream queries can return stale data referencing entities that
no longer have a valid parent chain.

## Acceptance Criteria

1. After deleting a department, **no employees** that belonged to teams in
   that department remain in the employee store.
2. After deleting a department, **no assignments** linked to employees of
   that department remain in the assignment store.
3. Deleting one department must **not affect** any entities belonging to
   other departments.
4. All existing tests in `test_crud.py` continue to pass.
5. All tests in `test_cascade.py` pass.

## Constraints
- Do not break existing tests
- Max cycles: 15
