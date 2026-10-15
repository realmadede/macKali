#!/usr/bin/env bash
# macKali Test Suite
# Runs non-destructive unit and integration checks across scripts, manifests, and commands.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
C_RESET="\033[0m"
C_GREEN="\033[32m"
C_RED="\033[31m"
C_CYAN="\033[36m"
C_BOLD="\033[1m"

PASSED=0
FAILED=0

pass() {
  echo -e "  ${C_GREEN}[PASS]${C_RESET} $*"
  PASSED=$((PASSED + 1))
}

fail() {
  echo -e "  ${C_RED}[FAIL]${C_RESET} $*" >&2
  FAILED=$((FAILED + 1))
}

run_test() {
  local name="$1"
  shift
  echo -e "${C_BOLD}Running Test:${C_RESET} $name"
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
  echo ""
}

# Temporary sandbox directory for isolated testing
SANDBOX="$(mktemp -d /tmp/mackali-test-XXXXXX)"
cleanup() {
  rm -rf "$SANDBOX"
}
trap cleanup EXIT

echo "============================================================"
echo "                 macKali Automated Test Suite               "
echo "============================================================"
echo "Sandbox: $SANDBOX"
echo ""

# Test 1: Shell script syntax check (bash -n)
test_shell_syntax() {
  local scripts=(
    "$REPO_ROOT/install.sh"
    "$REPO_ROOT/build.sh"
    "$REPO_ROOT/scripts/install.sh"
    "$REPO_ROOT/scripts/compat-check.sh"
    "$REPO_ROOT/scripts/backup.sh"
    "$REPO_ROOT/scripts/restore.sh"
    "$REPO_ROOT/scripts/uninstall.sh"
    "$REPO_ROOT/scripts/lib/common.sh"
    "$REPO_ROOT/themes/cursors/build.sh"
    "$REPO_ROOT/themes/cursors/install.sh"
  )
  for s in "${scripts[@]}"; do
    if ! bash -n "$s"; then
      echo "Syntax error in $s"
      return 1
    fi
  done
  return 0
}
run_test "Shell scripts syntax check (bash -n)" test_shell_syntax

# Test 2: JSON Syntax Validation
test_json_syntax() {
  python3 -c "
import json, glob, sys
files = glob.glob('$REPO_ROOT/extensions/**/*.json', recursive=True)
if not files:
    sys.exit(1)
for f in files:
    with open(f) as fp:
        json.load(fp)
"
}
run_test "JSON syntax validation (all manifests & presets)" test_json_syntax

# Test 3: Manifest Schema Compliance
test_schema_compliance() {
  python3 -c "
import json, glob, sys
with open('$REPO_ROOT/extensions/manifest-schema.json') as f:
    schema = json.load(f)
req = set(schema.get('required', []))
for m in glob.glob('$REPO_ROOT/extensions/manifests/*.json'):
    with open(m) as f:
        data = json.load(f)
    diff = req - set(data.keys())
    if diff:
        print(f'Missing required fields {diff} in {m}')
        sys.exit(1)
"
}
run_test "Extension manifest schema compliance" test_schema_compliance

# Test 4: CLI --help flags on all executable scripts
test_cli_help() {
  "$REPO_ROOT/install.sh" --help >/dev/null
  "$REPO_ROOT/scripts/install.sh" --help >/dev/null
  "$REPO_ROOT/scripts/backup.sh" --help >/dev/null
  "$REPO_ROOT/scripts/restore.sh" --help >/dev/null
  "$REPO_ROOT/scripts/uninstall.sh" --help >/dev/null
  "$REPO_ROOT/themes/cursors/install.sh" --help >/dev/null
}
run_test "CLI --help flags execution and zero exit codes" test_cli_help

# Test 5: Compatibility check command
test_compat_check() {
  "$REPO_ROOT/scripts/compat-check.sh" >/dev/null
}
run_test "Compatibility checker (scripts/compat-check.sh)" test_compat_check

# Test 6: Dry-run installer command
test_dry_run() {
  "$REPO_ROOT/scripts/install.sh" --preset balanced --dry-run >/dev/null
  "$REPO_ROOT/scripts/install.sh" --preset minimal --dry-run >/dev/null
  "$REPO_ROOT/scripts/install.sh" --preset full --dry-run >/dev/null
}
run_test "Installer dry-run across all presets (scripts/install.sh --dry-run)" test_dry_run

# Test 7: Isolated Backup and Restore
test_backup_restore() {
  local backup_dest="$SANDBOX/backup_test"
  "$REPO_ROOT/scripts/backup.sh" --dest "$backup_dest" >/dev/null
  [ -f "$backup_dest/backup-meta.json" ] || return 1
  [ -f "$backup_dest/org_gnome_desktop.dconf" ] || return 1
  [ -f "$backup_dest/org_gnome_shell.dconf" ] || return 1
  # Test restoration from this specific isolated backup
  "$REPO_ROOT/scripts/restore.sh" --from "$backup_dest" >/dev/null
}
run_test "Isolated backup creation & restore verification" test_backup_restore

# Test 8: Cursor Installation & Uninstallation lifecycle
test_cursor_lifecycle() {
  # Install
  "$REPO_ROOT/themes/cursors/install.sh" >/dev/null
  local target="$HOME/.local/share/icons/WhiteSur-cursors"
  [ -d "$target/cursors" ] || return 1
  [ -f "$target/index.theme" ] || return 1

  # Uninstall
  "$REPO_ROOT/themes/cursors/install.sh" --uninstall >/dev/null
  [ ! -d "$target" ] || return 1
}
run_test "Cursor installation & uninstallation lifecycle" test_cursor_lifecycle

echo "============================================================"
echo -e "Test Results: ${C_GREEN}$PASSED passed${C_RESET}, ${C_RED}$FAILED failed${C_RESET}"
echo "============================================================"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
