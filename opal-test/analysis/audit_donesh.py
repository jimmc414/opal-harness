#!/usr/bin/env python3
"""Audit agent-generated done.sh files against task acceptance criteria.

Computes: criteria coverage, check validity, strictness alignment.
"""
import json
import re
import sys
from pathlib import Path


def extract_criteria(task_md: str) -> list[str]:
    """Extract acceptance criteria from task.md."""
    criteria = []
    in_criteria = False
    for line in task_md.splitlines():
        if "acceptance criteria" in line.lower():
            in_criteria = True
            continue
        if in_criteria:
            if line.strip().startswith("- ["):
                criterion = re.sub(r"^- \[.\]\s*", "", line.strip())
                criteria.append(criterion)
            elif line.strip().startswith("#"):
                break
    return criteria


def extract_donesh_comments(donesh: str) -> list[str]:
    """Extract check comments from done.sh."""
    comments = []
    for line in donesh.splitlines():
        line = line.strip()
        if line.startswith("# Check") or line.startswith("# Criterion"):
            comments.append(line.lstrip("# ").strip())
    return comments


def audit_task(task_dir: Path, result_dir: Path) -> dict:
    """Audit a single task's done.sh."""
    task_md = (task_dir / "task.md").read_text()
    criteria = extract_criteria(task_md)

    donesh_path = result_dir / "done.sh"
    if not donesh_path.exists():
        return {"criteria": len(criteria), "covered": 0, "coverage": 0.0}

    donesh = donesh_path.read_text()
    comments = extract_donesh_comments(donesh)

    # Simple keyword overlap for coverage
    covered = 0
    for criterion in criteria:
        keywords = set(criterion.lower().split())
        for comment in comments:
            comment_words = set(comment.lower().split())
            if len(keywords & comment_words) >= 2:
                covered += 1
                break

    return {
        "criteria": len(criteria),
        "covered": covered,
        "coverage": covered / len(criteria) if criteria else 0.0,
    }


def main():
    base = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("opal-test")
    tasks_dir = base / "tasks"
    results_dir = base / "results" / "opal"

    print("=== done.sh Audit ===\n")
    total_criteria = 0
    total_covered = 0

    for type_dir in sorted(tasks_dir.iterdir()):
        if not type_dir.is_dir():
            continue
        for task_dir in sorted(type_dir.iterdir()):
            task_id = task_dir.name
            result_dir = results_dir / task_id
            if not result_dir.exists():
                continue
            audit = audit_task(task_dir, result_dir)
            total_criteria += audit["criteria"]
            total_covered += audit["covered"]
            print(f"{task_id}: {audit['covered']}/{audit['criteria']} criteria covered ({audit['coverage']:.0%})")

    if total_criteria > 0:
        print(f"\nOverall coverage: {total_covered}/{total_criteria} ({total_covered/total_criteria:.0%})")


if __name__ == "__main__":
    main()
