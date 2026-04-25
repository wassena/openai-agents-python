#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting pass/fail status.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
LOG_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/logs"
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-60}
PYTHON_BIN=${PYTHON_BIN:-python}
FAILED_EXAMPLES=()
PASSED_EXAMPLES=()
SKIPPED_EXAMPLES=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[examples-auto-run] $*"; }
warn() { echo "[examples-auto-run] WARN: $*" >&2; }
err()  { echo "[examples-auto-run] ERROR: $*" >&2; }

require_command() {
  if ! command -v "$1" &>/dev/null; then
    err "Required command '$1' not found. Please install it and retry."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
require_command "$PYTHON_BIN"
require_command timeout

mkdir -p "$LOG_DIR"

if [[ ! -d "$EXAMPLES_DIR" ]]; then
  err "Examples directory not found: $EXAMPLES_DIR"
  exit 1
fi

# ---------------------------------------------------------------------------
# Discover examples
# ---------------------------------------------------------------------------
# An example is any *.py file directly inside examples/ or one level deep.
mapfile -t EXAMPLE_FILES < <(
  find "$EXAMPLES_DIR" -maxdepth 2 -name '*.py' | sort
)

if [[ ${#EXAMPLE_FILES[@]} -eq 0 ]]; then
  warn "No example files found under $EXAMPLES_DIR"
  exit 0
fi

log "Discovered ${#EXAMPLE_FILES[@]} example file(s)."

# ---------------------------------------------------------------------------
# Run each example
# ---------------------------------------------------------------------------
run_example() {
  local example_path="$1"
  local rel_path="${example_path#"$REPO_ROOT/"}"
  local safe_name
  safe_name=$(echo "$rel_path" | tr '/' '_' | tr ' ' '_')
  local log_file="${LOG_DIR}/${safe_name}.log"

  # Skip examples that require interactive input (heuristic: contain 'input(')
  if grep -q 'input(' "$example_path" 2>/dev/null; then
    log "SKIP (interactive): $rel_path"
    SKIPPED_EXAMPLES+=("$rel_path")
    return
  fi

  # Skip examples that explicitly opt out via a marker comment
  if grep -q '# skip-auto-run' "$example_path" 2>/dev/null; then
    log "SKIP (opted-out): $rel_path"
    SKIPPED_EXAMPLES+=("$rel_path")
    return
  fi

  log "RUN: $rel_path"
  local start_ts
  start_ts=$(date +%s)

  if timeout "$TIMEOUT_SECONDS" "$PYTHON_BIN" "$example_path" \
       > "$log_file" 2>&1; then
    local end_ts
    end_ts=$(date +%s)
    local elapsed=$(( end_ts - start_ts ))
    log "PASS ($elapsed s): $rel_path"
    PASSED_EXAMPLES+=("$rel_path")
  else
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      err "TIMEOUT (>${TIMEOUT_SECONDS}s): $rel_path  →  $log_file"
    else
      err "FAIL (exit $exit_code): $rel_path  →  $log_file"
    fi
    FAILED_EXAMPLES+=("$rel_path")
  fi
}

for example in "${EXAMPLE_FILES[@]}"; do
  run_example "$example"
done

# ---------------------------------------------------------------------------
# Summary report
# ---------------------------------------------------------------------------
echo ""
log "==============================="
log "Examples Auto-Run Summary"
log "==============================="
log "  Passed : ${#PASSED_EXAMPLES[@]}"
log "  Failed : ${#FAILED_EXAMPLES[@]}"
log "  Skipped: ${#SKIPPED_EXAMPLES[@]}"
log "  Logs   : $LOG_DIR"

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  echo ""
  err "The following examples FAILED:"
  for f in "${FAILED_EXAMPLES[@]}"; do
    err "  - $f"
  done
  exit 1
fi

log "All runnable examples passed."
exit 0
