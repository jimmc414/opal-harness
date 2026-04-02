#!/usr/bin/env python3
"""Filter SWE-bench Lite for OPAL Phase 2 candidates.

Outputs a ranked table of instances suitable for bare-vs-OPAL testing.
Criteria: pure Python, clear problem statement, focused test patch,
few FAIL_TO_PASS tests, no complex environment needs.
"""
import json
import sys
from datasets import load_dataset

# Repos that need complex setup (databases, C extensions, etc.)
COMPLEX_REPOS = {
    "django/django",       # needs database backend for most tests
    "scikit-learn/scikit-learn",  # needs compiled C/Cython extensions
    "matplotlib/matplotlib",     # needs GUI backends, compiled extensions
    "pandas-dev/pandas",         # needs compiled extensions
}

# Repos known to work well with pip install -e .
PREFERRED_REPOS = {
    "sympy/sympy",
    "pytest-dev/pytest",
    "sphinx-doc/sphinx",
    "pylint-dev/pylint",
    "astropy/astropy",
    "psf/requests",
    "pallets/flask",
    "mwaskom/seaborn",
    "pydata/xarray",
}


def score_instance(inst):
    """Score an instance for OPAL suitability. Higher = better candidate."""
    score = 0
    repo = inst["repo"].replace("__", "/")

    # Prefer repos that are easy to set up
    if repo in PREFERRED_REPOS:
        score += 20
    if repo in COMPLEX_REPOS:
        score -= 100  # hard exclude

    # Problem statement quality
    ps_len = len(inst["problem_statement"])
    if ps_len < 200:
        score -= 30  # too vague
    elif ps_len > 500:
        score += 10  # detailed description
    if ps_len > 3000:
        score -= 5   # possibly too noisy

    # Patch complexity (gold solution)
    patch_lines = len(inst["patch"].split("\n"))
    if 5 <= patch_lines <= 30:
        score += 15  # focused fix
    elif 30 < patch_lines <= 60:
        score += 10  # moderate fix
    elif patch_lines > 100:
        score -= 10  # very complex

    # Test patch size
    test_lines = len(inst["test_patch"].split("\n"))
    if test_lines > 100:
        score -= 15  # complex eval
    elif test_lines <= 50:
        score += 10  # focused test

    # FAIL_TO_PASS count
    ftp = json.loads(inst["FAIL_TO_PASS"])
    if len(ftp) <= 3:
        score += 15
    elif len(ftp) <= 5:
        score += 5
    else:
        score -= 10

    # PASS_TO_PASS count (fewer = simpler eval)
    ptp = json.loads(inst["PASS_TO_PASS"])
    if len(ptp) <= 20:
        score += 5

    # Hints available (we won't use them, but their presence suggests
    # the task is harder — the original submitter needed hints)
    if inst["hints_text"] and len(inst["hints_text"]) > 100:
        score += 5  # harder task, good for differentiation

    return score


def main():
    print("Loading SWE-bench Lite...", file=sys.stderr)
    ds = load_dataset("princeton-nlp/SWE-bench_Lite", split="test")
    print(f"Loaded {len(ds)} instances", file=sys.stderr)

    candidates = []
    for inst in ds:
        repo = inst["repo"].replace("__", "/")
        if repo in COMPLEX_REPOS:
            continue

        ps_len = len(inst["problem_statement"])
        if ps_len < 200:
            continue

        ftp = json.loads(inst["FAIL_TO_PASS"])
        if len(ftp) > 5:
            continue

        test_lines = len(inst["test_patch"].split("\n"))
        if test_lines > 150:
            continue

        s = score_instance(inst)
        candidates.append((s, inst))

    candidates.sort(key=lambda x: -x[0])

    # Print header
    print(f"{'Score':>5} {'Instance ID':<45} {'Repo':<25} "
          f"{'PS Len':>6} {'Patch':>5} {'Tests':>5} {'FTP':>4} "
          f"{'Problem Preview'}")
    print("-" * 160)

    for score, inst in candidates[:40]:
        repo = inst["repo"].replace("__", "/")
        ftp = json.loads(inst["FAIL_TO_PASS"])
        patch_lines = len(inst["patch"].split("\n"))
        test_lines = len(inst["test_patch"].split("\n"))
        preview = inst["problem_statement"][:80].replace("\n", " ")

        print(f"{score:>5} {inst['instance_id']:<45} {repo:<25} "
              f"{len(inst['problem_statement']):>6} {patch_lines:>5} "
              f"{test_lines:>5} {len(ftp):>4} {preview}")

    # Also dump top 20 as JSON for create_task.py
    top = [inst["instance_id"] for _, inst in candidates[:20]]
    json_path = "opal-test/swebench/top_candidates.json"
    with open(json_path, "w") as f:
        json.dump(top, f, indent=2)
    print(f"\nTop 20 instance IDs saved to {json_path}", file=sys.stderr)

    # Print repo distribution
    print("\n--- Repo distribution (top 40) ---")
    from collections import Counter
    repos = Counter(inst["repo"].replace("__", "/")
                    for _, inst in candidates[:40])
    for repo, count in repos.most_common():
        print(f"  {repo}: {count}")


if __name__ == "__main__":
    main()
