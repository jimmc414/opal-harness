"""Validates Dockerfile structure for multi-stage build best practices."""
import os
import re
import sys


def validate_dockerfile(filepath):
    with open(filepath) as f:
        content = f.read()
        lines = content.strip().split('\n')

    results = {}

    from_lines = [l for l in lines if l.strip().upper().startswith('FROM')]
    results['stage_count'] = len(from_lines)
    results['is_multi_stage'] = len(from_lines) >= 2

    if from_lines:
        last_from = from_lines[-1].lower()
        results['final_base_slim'] = 'slim' in last_from or 'alpine' in last_from

    copy_lines = [(i, l) for i, l in enumerate(lines)
                  if l.strip().upper().startswith('COPY')]
    pip_lines = [(i, l) for i, l in enumerate(lines)
                 if 'pip install' in l.lower()]

    if copy_lines and pip_lines:
        req_copies = [(i, l) for i, l in copy_lines
                      if 'requirements' in l.lower()]
        if req_copies:
            results['requirements_before_source'] = (
                req_copies[0][0] < copy_lines[-1][0]
            )

    user_lines = [l for l in lines if l.strip().upper().startswith('USER')]
    results['has_non_root_user'] = len(user_lines) > 0

    if len(from_lines) >= 2:
        final_stage = content.split('FROM')[-1]
        results['no_dev_deps_in_final'] = 'requirements-dev' not in final_stage
    else:
        results['no_dev_deps_in_final'] = False

    dockerignore_path = os.path.join(os.path.dirname(filepath), '.dockerignore')
    if os.path.exists(dockerignore_path):
        with open(dockerignore_path) as f:
            ignore_content = f.read()
        results['dockerignore_has_content'] = len(ignore_content.strip()) > 0
        results['dockerignore_excludes_git'] = '.git' in ignore_content
        results['dockerignore_excludes_pycache'] = '__pycache__' in ignore_content
        results['dockerignore_excludes_tests'] = (
            'tests' in ignore_content or 'test' in ignore_content
        )
    else:
        results['dockerignore_has_content'] = False

    return results


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "Dockerfile"
    results = validate_dockerfile(path)
    for k, v in sorted(results.items()):
        status = "PASS" if v else "FAIL"
        print(f"  {status}: {k} = {v}")
