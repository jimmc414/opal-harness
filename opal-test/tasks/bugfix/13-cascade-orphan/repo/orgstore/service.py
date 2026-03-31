from orgstore.queries import teams_by_department


class OrgService:
    def __init__(self, dept_store, team_store, employee_store, assignment_store):
        self.dept_store = dept_store
        self.team_store = team_store
        self.employee_store = employee_store
        self.assignment_store = assignment_store

    def delete_department(self, department_id):
        dept = self.dept_store.get(department_id)
        if dept is None:
            return False

        teams = teams_by_department(self.team_store, department_id)
        for team in teams:
            self.team_store.remove(team.id)

        self.dept_store.remove(department_id)
        return True
