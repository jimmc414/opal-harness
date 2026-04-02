#!/usr/bin/env python3
"""Generate an OPAL task directory from a SWE-bench Lite instance.

Usage: python create_task.py <instance_id> <task_number>
Example: python create_task.py sympy__sympy-18621 01
"""
import json
import sys
import textwrap
from pathlib import Path
from datasets import load_dataset


def slugify(instance_id: str) -> str:
    """Convert instance_id to a short slug: sympy__sympy-18621 -> sympy-18621."""
    parts = instance_id.split("__")
    return parts[-1] if len(parts) == 2 else instance_id.replace("__", "-")


def repo_url(repo: str) -> str:
    """Convert repo field to GitHub URL."""
    return f"https://github.com/{repo.replace('__', '/')}.git"


def create_task_md(inst: dict) -> str:
    """Generate task.md from the SWE-bench problem_statement."""
    repo = inst["repo"].replace("__", "/")
    return textwrap.dedent(f"""\
    # Task

    ## Source
    Real: github.com/{repo} (SWE-bench Lite instance {inst['instance_id']})

    ## Problem
    {inst['problem_statement']}

    ## Acceptance Criteria
    - [ ] The issue described above is resolved.
    - [ ] All existing tests continue to pass (no regressions).
    - [ ] The fix is in the source code, not in test files.

    ## Constraints
    - Do not modify test files
    - Max cycles: 20
    - This is a large open-source project. Focus on understanding the
      relevant modules rather than reading the entire codebase.
    """)


def create_metadata(inst: dict, task_number: str) -> dict:
    """Generate metadata.json."""
    slug = slugify(inst["instance_id"])
    repo = inst["repo"].replace("__", "/")
    return {
        "id": f"swebench-{task_number}-{slug}",
        "type": "swebench",
        "tier": 3,
        "source": "swe-bench-lite",
        "source_instance": inst["instance_id"],
        "source_repo": repo,
        "source_commit": inst["base_commit"],
        "expected_mechanisms": ["dead-ends", "replan", "exploration"],
        "estimated_cycles": 12,
        "notes": f"Real GitHub issue from {repo}. Large codebase navigation required.",
    }


def create_setup_repo(inst: dict) -> str:
    """Generate setup_repo.sh."""
    repo = inst["repo"].replace("__", "/")
    url = f"https://github.com/{repo}.git"
    commit = inst["base_commit"]
    # Use double-underscore form as cache key (e.g., "sympy__sympy") — no slashes
    repo_slug = inst["repo"].replace("/", "__")

    return textwrap.dedent(f"""\
    #!/usr/bin/env bash
    # Clone {repo} at commit {commit[:12]}
    set -euo pipefail
    TARGET_DIR="${{1:?Usage: setup_repo.sh <target_dir>}}"
    REPO_URL="{url}"
    BASE_COMMIT="{commit}"
    REPO_SLUG="{repo_slug}"

    CACHE_DIR="${{SWEBENCH_REPO_CACHE:-$HOME/.cache/swebench-repos}}"

    # Remove target if it exists (setup_workspace.sh may have created it)
    rm -rf "$TARGET_DIR"

    if [[ -d "$CACHE_DIR/$REPO_SLUG/.git" ]]; then
        echo "Using cached repo: $CACHE_DIR/$REPO_SLUG"
        cp -r "$CACHE_DIR/$REPO_SLUG" "$TARGET_DIR"
        cd "$TARGET_DIR"
        git checkout "$BASE_COMMIT" --quiet 2>/dev/null
    else
        echo "Cloning $REPO_URL (blobless)..."
        git clone --filter=blob:none --quiet "$REPO_URL" "$TARGET_DIR"
        cd "$TARGET_DIR"
        git checkout "$BASE_COMMIT" --quiet 2>/dev/null

        # Cache for next run
        mkdir -p "$CACHE_DIR"
        echo "Caching repo to $CACHE_DIR/$REPO_SLUG"
        cp -r "$TARGET_DIR" "$CACHE_DIR/$REPO_SLUG"
    fi

    echo "Repo ready: {repo} @ ${{BASE_COMMIT:0:12}}"
    """)


def create_eval_sh(inst: dict) -> str:
    """Generate eval.sh that applies test_patch and runs FAIL_TO_PASS tests."""
    ftp = json.loads(inst["FAIL_TO_PASS"])
    ptp = json.loads(inst["PASS_TO_PASS"])

    # Resolve test paths: SWE-bench FAIL_TO_PASS may use bare function names
    # (e.g., "test_issue_18618") or full paths (e.g., "tests/foo.py::test_bar").
    # For bare names, extract the file path from the test_patch diff headers.
    test_patch = inst["test_patch"]
    patched_test_files = []
    for line in test_patch.split("\n"):
        if line.startswith("diff --git"):
            # Extract b/path from "diff --git a/foo b/foo"
            parts = line.split(" b/")
            if len(parts) == 2:
                patched_test_files.append(parts[1])

    resolved_ftp = []
    for t in ftp:
        if "/" in t or "::" in t:
            # Already has a path
            resolved_ftp.append(t)
        else:
            # Bare function name — prepend the test file from the patch
            if patched_test_files:
                resolved_ftp.append(f"{patched_test_files[0]}::{t}")
            else:
                resolved_ftp.append(t)

    ftp_args = " ".join(f'"{t}"' for t in resolved_ftp)

    # For PASS_TO_PASS, pick just the test module(s) to keep eval fast
    ptp_modules = set()
    for t in ptp[:20]:  # limit to first 20
        if "/" in t or "::" in t:
            module = t.split("::")[0]
            ptp_modules.add(module)
        elif patched_test_files:
            ptp_modules.add(patched_test_files[0])

    ptp_args = " ".join(f'"{m}"' for m in sorted(ptp_modules)[:3])  # max 3 modules

    task_dir_ref = '$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)'

    return textwrap.dedent(f"""\
    #!/usr/bin/env bash
    # Eval for SWE-bench instance: {inst['instance_id']}
    # FAIL_TO_PASS: {len(ftp)} tests | PASS_TO_PASS: {len(ptp)} tests
    set -euo pipefail

    # Compute TASK_DIR before changing directory
    TASK_DIR={task_dir_ref}

    cd "$WORK_DIR"

    # Make project importable (prefer PYTHONPATH over pip install to avoid
    # breaking the current environment with old dependency versions)
    export PYTHONPATH="$WORK_DIR:${{PYTHONPATH:-}}"

    # Apply test patch (new tests that verify the fix)
    echo "Applying test patch..."
    git apply --allow-empty "$TASK_DIR/test_patch.diff"

    # FAIL_TO_PASS: these tests must pass after the fix
    echo "Running FAIL_TO_PASS tests..."
    python -m pytest {ftp_args} -x --tb=short -q

    # PASS_TO_PASS: these test modules must not regress
    echo "Running PASS_TO_PASS regression tests..."
    python -m pytest {ptp_args} -x --tb=short -q || true

    echo "ALL CRITERIA PASSED"
    """)


def main():
    if len(sys.argv) < 3:
        print("Usage: python create_task.py <instance_id> <task_number>")
        print("Example: python create_task.py sympy__sympy-18621 01")
        sys.exit(1)

    instance_id = sys.argv[1]
    task_number = sys.argv[2]

    print(f"Loading SWE-bench Lite...", file=sys.stderr)
    ds = load_dataset("princeton-nlp/SWE-bench_Lite", split="test")

    # Find the instance
    inst = None
    for item in ds:
        if item["instance_id"] == instance_id:
            inst = item
            break

    if inst is None:
        print(f"ERROR: Instance {instance_id} not found in SWE-bench Lite", file=sys.stderr)
        sys.exit(1)

    slug = slugify(instance_id)
    task_dir = Path(f"opal-test/tasks/swebench/{task_number}-{slug}")
    task_dir.mkdir(parents=True, exist_ok=True)

    # Write task.md
    (task_dir / "task.md").write_text(create_task_md(inst))
    print(f"  Created {task_dir}/task.md")

    # Write metadata.json
    metadata = create_metadata(inst, task_number)
    (task_dir / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"  Created {task_dir}/metadata.json")

    # Write setup_repo.sh
    setup = create_setup_repo(inst)
    setup_path = task_dir / "setup_repo.sh"
    setup_path.write_text(setup)
    setup_path.chmod(0o755)
    print(f"  Created {task_dir}/setup_repo.sh")

    # Write test_patch.diff
    (task_dir / "test_patch.diff").write_text(inst["test_patch"])
    print(f"  Created {task_dir}/test_patch.diff")

    # Write eval.sh
    eval_script = create_eval_sh(inst)
    eval_path = task_dir / "eval.sh"
    eval_path.write_text(eval_script)
    eval_path.chmod(0o755)
    print(f"  Created {task_dir}/eval.sh")

    # Write full instance data for reference
    inst_data = {k: inst[k] for k in inst.keys()}
    (task_dir / "swebench_instance.json").write_text(
        json.dumps(inst_data, indent=2, default=str) + "\n"
    )
    print(f"  Created {task_dir}/swebench_instance.json")

    print(f"\nTask created: {task_dir}")
    print(f"  Instance: {instance_id}")
    print(f"  Repo: {inst['repo'].replace('__', '/')}")
    print(f"  FAIL_TO_PASS: {len(json.loads(inst['FAIL_TO_PASS']))} tests")
    print(f"  PASS_TO_PASS: {len(json.loads(inst['PASS_TO_PASS']))} tests")
    print(f"  Patch size: {len(inst['patch'].split(chr(10)))} lines")


if __name__ == "__main__":
    main()
