from orgstore.models import Department, Team, Employee, Assignment
from orgstore.store import EntityStore


class TestDepartmentCrud:
    def test_add_and_get(self):
        store = EntityStore()
        dept = Department(name="Engineering", id="d1")
        store.add(dept)
        assert store.get("d1") is dept

    def test_remove(self):
        store = EntityStore()
        dept = Department(name="Engineering", id="d1")
        store.add(dept)
        removed = store.remove("d1")
        assert removed is dept
        assert store.get("d1") is None

    def test_count(self):
        store = EntityStore()
        store.add(Department(name="A", id="d1"))
        store.add(Department(name="B", id="d2"))
        assert store.count() == 2


class TestTeamCrud:
    def test_add_and_get(self):
        store = EntityStore()
        team = Team(name="Backend", department_id="d1", id="t1")
        store.add(team)
        assert store.get("t1") is team

    def test_remove(self):
        store = EntityStore()
        team = Team(name="Backend", department_id="d1", id="t1")
        store.add(team)
        store.remove("t1")
        assert store.get("t1") is None


class TestEmployeeCrud:
    def test_add_and_get(self):
        store = EntityStore()
        emp = Employee(name="Alice", team_id="t1", id="e1")
        store.add(emp)
        assert store.get("e1") is emp

    def test_remove(self):
        store = EntityStore()
        emp = Employee(name="Alice", team_id="t1", id="e1")
        store.add(emp)
        store.remove("e1")
        assert store.get("e1") is None


class TestAssignmentCrud:
    def test_add_and_get(self):
        store = EntityStore()
        assign = Assignment(title="Task A", employee_id="e1", id="a1")
        store.add(assign)
        assert store.get("a1") is assign

    def test_remove(self):
        store = EntityStore()
        assign = Assignment(title="Task A", employee_id="e1", id="a1")
        store.add(assign)
        store.remove("a1")
        assert store.get("a1") is None

    def test_all(self):
        store = EntityStore()
        a1 = Assignment(title="Task A", employee_id="e1", id="a1")
        a2 = Assignment(title="Task B", employee_id="e2", id="a2")
        store.add(a1)
        store.add(a2)
        assert len(store.all()) == 2
