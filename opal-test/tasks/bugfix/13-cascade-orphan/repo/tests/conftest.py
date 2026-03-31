import pytest

from orgstore.models import Department, Team, Employee, Assignment
from orgstore.store import EntityStore
from orgstore.service import OrgService


@pytest.fixture
def stores():
    return {
        "dept": EntityStore(),
        "team": EntityStore(),
        "employee": EntityStore(),
        "assignment": EntityStore(),
    }


@pytest.fixture
def seeded_stores(stores):
    dept_eng = Department(name="Engineering", id="dept-eng")
    dept_sales = Department(name="Sales", id="dept-sales")
    stores["dept"].add(dept_eng)
    stores["dept"].add(dept_sales)

    team_backend = Team(name="Backend", department_id="dept-eng", id="team-backend")
    team_frontend = Team(name="Frontend", department_id="dept-eng", id="team-frontend")
    team_outreach = Team(name="Outreach", department_id="dept-sales", id="team-outreach")
    stores["team"].add(team_backend)
    stores["team"].add(team_frontend)
    stores["team"].add(team_outreach)

    emp_alice = Employee(name="Alice", team_id="team-backend", id="emp-alice")
    emp_bob = Employee(name="Bob", team_id="team-frontend", id="emp-bob")
    emp_carol = Employee(name="Carol", team_id="team-frontend", id="emp-carol")
    emp_dave = Employee(name="Dave", team_id="team-outreach", id="emp-dave")
    stores["employee"].add(emp_alice)
    stores["employee"].add(emp_bob)
    stores["employee"].add(emp_carol)
    stores["employee"].add(emp_dave)

    assign_1 = Assignment(title="API Design", employee_id="emp-alice", id="assign-1")
    assign_2 = Assignment(title="UI Revamp", employee_id="emp-bob", id="assign-2")
    assign_3 = Assignment(title="CSS Cleanup", employee_id="emp-carol", id="assign-3")
    assign_4 = Assignment(title="Campaign Plan", employee_id="emp-dave", id="assign-4")
    stores["assignment"].add(assign_1)
    stores["assignment"].add(assign_2)
    stores["assignment"].add(assign_3)
    stores["assignment"].add(assign_4)

    return stores


@pytest.fixture
def service(seeded_stores):
    return OrgService(
        dept_store=seeded_stores["dept"],
        team_store=seeded_stores["team"],
        employee_store=seeded_stores["employee"],
        assignment_store=seeded_stores["assignment"],
    )
