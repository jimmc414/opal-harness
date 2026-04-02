#!/usr/bin/env bash
# Check OPAL protocol adherence from archived .opal/ directory.
# Usage: check_artifacts.sh <opal_result_dir>
# Example: check_artifacts.sh opal-test/results/opal/bugfix-01-whitespace-strip
set -euo pipefail

RESULT_DIR="$1"
ARCHIVE="$RESULT_DIR/opal_archive"

if [[ ! -d "$ARCHIVE" ]]; then
    echo "ERROR: No opal_archive/ found in $RESULT_DIR" >&2
    exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REPORT=""

check() {
    local label="$1"
    local status="$2"  # PASS, FAIL, WARN
    local detail="$3"

    case "$status" in
        PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
        FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
        WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    esac

    REPORT+="  [$status] $label"
    if [[ -n "$detail" ]]; then
        REPORT+=" -- $detail"
    fi
    REPORT+=$'\n'
}

# ---------------------------------------------------------------
# Check 1: state.md exists and has all 7 fields
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/state.md" ]]; then
    STATE_CONTENT=$(cat "$ARCHIVE/state.md")
    MISSING_FIELDS=""
    for field in "Phase:" "Cycle:" "Summary:" "Next Action:" "Blocking Issues:" "Artifacts:" "Check Command:"; do
        if ! echo "$STATE_CONTENT" | grep -q "$field"; then
            MISSING_FIELDS+="$field "
        fi
    done
    if [[ -z "$MISSING_FIELDS" ]]; then
        check "state.md has all 7 fields" "PASS" ""
    else
        check "state.md missing fields" "FAIL" "$MISSING_FIELDS"
    fi
else
    check "state.md exists" "FAIL" "file not found"
fi

# ---------------------------------------------------------------
# Check 2: Final phase is DONE, STUCK, or PAUSE
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/state.md" ]]; then
    # Extract phase value — handle bold markdown and various formats
    FINAL_PHASE=$(grep -oP '\*?\*?Phase:?\*?\*?\s*\K\S+' "$ARCHIVE/state.md" 2>/dev/null | head -1 || echo "UNKNOWN")
    if [[ "$FINAL_PHASE" =~ ^(DONE|STUCK|PAUSE)$ ]]; then
        check "Final phase is terminal" "PASS" "$FINAL_PHASE"
    else
        check "Final phase is terminal" "FAIL" "got '$FINAL_PHASE' (expected DONE/STUCK/PAUSE)"
    fi
fi

# ---------------------------------------------------------------
# Check 3: done.sh has acceptance criteria comments
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/checks/done.sh" ]]; then
    DONESH=$(cat "$ARCHIVE/checks/done.sh")

    # Count comment lines that look like acceptance criteria
    # Agents may use various formats: "# Acceptance:", "# Criterion:", "# Check:", or just descriptive comments
    CRITERIA_LINES=$(echo "$DONESH" | grep -cE '^#\s*(Acceptance|Criterion|Check|Test|AC[0-9]+):' 2>/dev/null || true)
    GENERAL_COMMENTS=$(echo "$DONESH" | grep -cE '^#' 2>/dev/null || true)

    if [[ $CRITERIA_LINES -gt 0 ]]; then
        check "done.sh has acceptance criteria comments" "PASS" "$CRITERIA_LINES criteria lines"
    elif [[ $GENERAL_COMMENTS -gt 3 ]]; then
        check "done.sh has acceptance criteria comments" "WARN" "no structured '# Acceptance:' lines but $GENERAL_COMMENTS comment lines found"
    else
        check "done.sh has acceptance criteria comments" "FAIL" "no acceptance criteria comments found"
    fi

    # Check that done.sh was modified from the placeholder
    if echo "$DONESH" | grep -q '^exit 1$' && [[ $(echo "$DONESH" | wc -l) -le 4 ]]; then
        check "done.sh was modified from placeholder" "FAIL" "still contains only 'exit 1'"
    else
        check "done.sh was modified from placeholder" "PASS" ""
    fi
else
    check "done.sh exists" "FAIL" "file not found"
fi

# ---------------------------------------------------------------
# Check 4: plan.md has Steps with checkboxes
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/plan.md" ]]; then
    PLAN_CONTENT=$(cat "$ARCHIVE/plan.md")
    if echo "$PLAN_CONTENT" | grep -qE '\[[ xX]\]'; then
        TOTAL_STEPS=$(echo "$PLAN_CONTENT" | grep -cE '\[[ xX]\]' || true)
        DONE_STEPS=$(echo "$PLAN_CONTENT" | grep -cE '\[[xX]\]' || true)
        check "plan.md has steps with checkboxes" "PASS" "$DONE_STEPS/$TOTAL_STEPS completed"
    else
        if [[ "$PLAN_CONTENT" == "Not yet created." ]]; then
            check "plan.md has steps with checkboxes" "FAIL" "plan was never created"
        else
            check "plan.md has steps with checkboxes" "WARN" "plan exists but no checkboxes found"
        fi
    fi
else
    check "plan.md exists" "FAIL" "file not found"
fi

# ---------------------------------------------------------------
# Check 5: log.md has at least 1 entry
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/log.md" ]]; then
    LOG_LINES=$(wc -l < "$ARCHIVE/log.md" | tr -d ' ')
    if [[ $LOG_LINES -gt 0 ]]; then
        # Try to count structured entries (headings, separators, cycle markers)
        LOG_ENTRIES=$(grep -cE '^(##|---|\*\*Cycle|### Cycle)' "$ARCHIVE/log.md" 2>/dev/null || true)
        if [[ $LOG_ENTRIES -gt 0 ]]; then
            check "log.md has entries" "PASS" "$LOG_ENTRIES structured entries, $LOG_LINES total lines"
        else
            check "log.md has entries" "WARN" "$LOG_LINES lines but no structured entry markers detected"
        fi
    else
        check "log.md has entries" "FAIL" "file is empty"
    fi
else
    check "log.md exists" "FAIL" "file not found"
fi

# ---------------------------------------------------------------
# Check 6: Dead Ends section in plan.md
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/plan.md" ]]; then
    if grep -qi 'Dead Ends' "$ARCHIVE/plan.md"; then
        # Count non-empty lines after "Dead Ends" heading until next heading or EOF
        DE_LINES=$(sed -n '/[Dd]ead [Ee]nds/,/^##[^#]/p' "$ARCHIVE/plan.md" \
            | tail -n +2 | grep -c '\S' 2>/dev/null || true)
        if [[ $DE_LINES -gt 0 ]]; then
            check "Dead Ends section populated" "PASS" "$DE_LINES non-empty lines"
        else
            check "Dead Ends section" "WARN" "section header exists but empty"
        fi
    else
        check "Dead Ends section" "WARN" "no Dead Ends section found in plan.md"
    fi
fi

# ---------------------------------------------------------------
# Check 7: Periodic checkpoint evidence (cycle >= 4)
# ---------------------------------------------------------------
if [[ -f "$ARCHIVE/state.md" ]]; then
    CYCLE_NUM=$(grep -oP '\*?\*?Cycle:?\*?\*?\s*\K\d+' "$ARCHIVE/state.md" 2>/dev/null | head -1 || echo 0)
    if [[ $CYCLE_NUM -ge 4 ]]; then
        SUMMARY=$(grep -oP '\*?\*?Summary:?\*?\*?\s*\K.*' "$ARCHIVE/state.md" 2>/dev/null | head -1 || echo "")
        if [[ "$SUMMARY" == "Task not yet started." ]]; then
            check "Periodic checkpoint (cycle $CYCLE_NUM)" "FAIL" "Summary still says 'Task not yet started' at cycle $CYCLE_NUM"
        elif [[ -z "$SUMMARY" ]]; then
            check "Periodic checkpoint (cycle $CYCLE_NUM)" "WARN" "Summary field is empty at cycle $CYCLE_NUM"
        else
            SUMMARY_PREVIEW="${SUMMARY:0:60}"
            check "Periodic checkpoint (cycle $CYCLE_NUM)" "PASS" "Summary updated: $SUMMARY_PREVIEW..."
        fi
    else
        check "Periodic checkpoint" "PASS" "cycle $CYCLE_NUM < 4, not required yet"
    fi
fi

# ---------------------------------------------------------------
# Report
# ---------------------------------------------------------------
TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
if [[ $TOTAL -gt 0 ]]; then
    ADHERENCE=$(awk "BEGIN {printf \"%.0f\", $PASS_COUNT * 100 / $TOTAL}")
else
    ADHERENCE=0
fi

echo ""
echo "================================================================"
echo "  OPAL Artifact Check: $(basename "$RESULT_DIR")"
echo "================================================================"
echo ""
echo "$REPORT"
echo "  Summary: $PASS_COUNT passed, $FAIL_COUNT failed, $WARN_COUNT warnings ($ADHERENCE% adherence)"
echo ""

# Machine-readable output
cat > "$RESULT_DIR/artifact_check.json" << JSONEOF
{
  "task": "$(basename "$RESULT_DIR")",
  "pass_count": $PASS_COUNT,
  "fail_count": $FAIL_COUNT,
  "warn_count": $WARN_COUNT,
  "adherence_pct": $ADHERENCE
}
JSONEOF

# Exit non-zero if any hard failures
[[ $FAIL_COUNT -eq 0 ]]
