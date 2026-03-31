#!/usr/bin/env python3
"""Compare OPAL vs bare baseline outcomes.

Computes: completion rate, cycle efficiency, recovery rate,
false completion rate, loop rate.
"""
import json
import sys
from pathlib import Path
from collections import defaultdict


def load_results(results_dir: Path, condition: str) -> dict:
    """Load all result files for a condition."""
    cond_dir = results_dir / condition
    results = {}
    if not cond_dir.exists():
        return results
    for task_dir in cond_dir.iterdir():
        if not task_dir.is_dir():
            continue
        result_file = task_dir / "result"
        if result_file.exists():
            results[task_dir.name] = {
                "pass": result_file.read_text().strip() == "PASS",
            }
            meta_file = task_dir / "metrics.json"
            if meta_file.exists():
                results[task_dir.name].update(json.loads(meta_file.read_text()))
    return results


def load_task_metadata(tasks_dir: Path) -> dict:
    """Load metadata.json for all tasks."""
    metadata = {}
    for type_dir in tasks_dir.iterdir():
        if not type_dir.is_dir():
            continue
        for task_dir in type_dir.iterdir():
            meta_file = task_dir / "metadata.json"
            if meta_file.exists():
                meta = json.loads(meta_file.read_text())
                metadata[meta["id"]] = meta
    return metadata


def compute_metrics(bare: dict, opal: dict, metadata: dict) -> dict:
    """Compute all primary metrics."""
    metrics = {"bare": {}, "opal": {}}

    for condition, results in [("bare", bare), ("opal", opal)]:
        total = len(results)
        if total == 0:
            continue
        passed = sum(1 for r in results.values() if r["pass"])
        metrics[condition]["completion_rate"] = passed / total
        metrics[condition]["total"] = total
        metrics[condition]["passed"] = passed

    # Per-tier breakdown
    for tier in [1, 2, 3]:
        tier_tasks = {k for k, v in metadata.items() if v.get("tier") == tier}
        for condition, results in [("bare", bare), ("opal", opal)]:
            tier_results = {k: v for k, v in results.items() if k in tier_tasks}
            total = len(tier_results)
            if total == 0:
                continue
            passed = sum(1 for r in tier_results.values() if r["pass"])
            metrics[condition][f"tier{tier}_completion"] = passed / total

    return metrics


def main():
    base = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("opal-test")
    tasks_dir = base / "tasks"
    results_dir = base / "results"

    metadata = load_task_metadata(tasks_dir)
    bare = load_results(results_dir, "bare")
    opal = load_results(results_dir, "opal")

    metrics = compute_metrics(bare, opal, metadata)

    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
