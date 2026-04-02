#!/usr/bin/env bash
# Clone sympy/sympy at commit d9b18c518d64
set -euo pipefail
TARGET_DIR="${1:?Usage: setup_repo.sh <target_dir>}"
REPO_URL="https://github.com/sympy/sympy.git"
BASE_COMMIT="d9b18c518d64d0ebe8e35a98c2fb519938b9b151"
REPO_SLUG="sympy__sympy"

CACHE_DIR="${SWEBENCH_REPO_CACHE:-$HOME/.cache/swebench-repos}"

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

echo "Repo ready: sympy/sympy @ ${BASE_COMMIT:0:12}"
