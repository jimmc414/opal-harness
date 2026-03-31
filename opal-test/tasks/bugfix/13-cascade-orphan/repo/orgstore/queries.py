def teams_by_department(store, department_id):
    return [
        e for e in store.all()
        if hasattr(e, 'department_id') and e.department_id == department_id
    ]


def employees_by_team(store, team_id):
    return [
        e for e in store.all()
        if hasattr(e, 'team_id') and e.team_id == team_id
    ]


def assignments_by_employee(store, employee_id):
    return [
        e for e in store.all()
        if hasattr(e, 'employee_id') and e.employee_id == employee_id
    ]
