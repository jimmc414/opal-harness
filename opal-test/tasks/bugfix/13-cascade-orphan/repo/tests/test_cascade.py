from orgstore.queries import (
    employees_by_team,
    assignments_by_employee,
)


class TestCascadeDelete:
    """Tests for cascading deletion of a department and all its children."""

    def test_department_removed(self, service, seeded_stores):
        service.delete_department("dept-eng")
        assert seeded_stores["dept"].get("dept-eng") is None

    def test_teams_removed(self, service, seeded_stores):
        service.delete_department("dept-eng")
        assert seeded_stores["team"].get("team-backend") is None
        assert seeded_stores["team"].get("team-frontend") is None

    def test_employees_removed(self, service, seeded_stores):
        service.delete_department("dept-eng")
        assert seeded_stores["employee"].get("emp-alice") is None
        assert seeded_stores["employee"].get("emp-bob") is None
        assert seeded_stores["employee"].get("emp-carol") is None

    def test_assignments_removed(self, service, seeded_stores):
        service.delete_department("dept-eng")
        assert seeded_stores["assignment"].get("assign-1") is None
        assert seeded_stores["assignment"].get("assign-2") is None
        assert seeded_stores["assignment"].get("assign-3") is None

    def test_no_assignments_for_eng_employees(self, service, seeded_stores):
        eng_emp_ids = {"emp-alice", "emp-bob", "emp-carol"}
        service.delete_department("dept-eng")
        remaining = seeded_stores["assignment"].all()
        remaining_emp_ids = {a.employee_id for a in remaining}
        overlap = eng_emp_ids & remaining_emp_ids
        assert len(overlap) == 0, (
            f"Assignments still reference deleted engineering employees: {overlap}"
        )

    def test_no_orphans_in_store(self, service, seeded_stores):
        service.delete_department("dept-eng")
        assert seeded_stores["dept"].count() == 1
        assert seeded_stores["team"].count() == 1
        assert seeded_stores["employee"].count() == 1
        assert seeded_stores["assignment"].count() == 1

    def test_other_department_unaffected(self, service, seeded_stores):
        service.delete_department("dept-eng")
        assert seeded_stores["dept"].get("dept-sales") is not None
        assert seeded_stores["team"].get("team-outreach") is not None
        assert seeded_stores["employee"].get("emp-dave") is not None
        assert seeded_stores["assignment"].get("assign-4") is not None

    def test_delete_nonexistent(self, service):
        result = service.delete_department("dept-nonexistent")
        assert result is False
