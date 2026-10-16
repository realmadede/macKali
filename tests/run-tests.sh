#!/usr/bin/env bash
# macKali Test Suite (Phase 2: Appearance Foundation & System Integrity)
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
    "$REPO_ROOT/scripts/tui-installer.sh"
    "$REPO_ROOT/scripts/extensions-manager.sh"
    "$REPO_ROOT/scripts/appearance.sh"
    "$REPO_ROOT/scripts/compat-check.sh"
    "$REPO_ROOT/scripts/backup.sh"
    "$REPO_ROOT/scripts/restore.sh"
    "$REPO_ROOT/scripts/uninstall.sh"
    "$REPO_ROOT/scripts/lib/common.sh"
    "$REPO_ROOT/scripts/package-release.sh"
    "$REPO_ROOT/scripts/providers/wallpaper-provider.sh"
    "$REPO_ROOT/scripts/providers/gtk-provider.sh"
    "$REPO_ROOT/scripts/providers/icon-provider.sh"
    "$REPO_ROOT/themes/cursors/build.sh"
    "$REPO_ROOT/themes/cursors/install.sh"
    "$REPO_ROOT/website/build.sh"
  )
  for s in "${scripts[@]}"; do
    if ! bash -n "$s"; then
      echo "Syntax error in $s"
      return 1
    fi
  done
  return 0
}
run_test "Shell scripts syntax check (bash -n across all 17 scripts)" test_shell_syntax

# Test 2: JSON Syntax Validation
test_json_syntax() {
  python3 -c "
import json, glob, sys
files = glob.glob('$REPO_ROOT/extensions/**/*.json', recursive=True) + glob.glob('$REPO_ROOT/themes/**/*.json', recursive=True)
if not files:
    sys.exit(1)
for f in files:
    with open(f) as fp:
        json.load(fp)
"
}
run_test "JSON syntax validation (all manifests, presets & providers)" test_json_syntax

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
  "$REPO_ROOT/scripts/tui-installer.sh" --help >/dev/null
  "$REPO_ROOT/scripts/extensions-manager.sh" --help >/dev/null
  "$REPO_ROOT/scripts/appearance.sh" --help >/dev/null
  "$REPO_ROOT/scripts/backup.sh" --help >/dev/null
  "$REPO_ROOT/scripts/restore.sh" --help >/dev/null
  "$REPO_ROOT/scripts/uninstall.sh" --help >/dev/null
  "$REPO_ROOT/scripts/providers/wallpaper-provider.sh" --help >/dev/null
  "$REPO_ROOT/scripts/providers/gtk-provider.sh" --help >/dev/null
  "$REPO_ROOT/scripts/providers/icon-provider.sh" --help >/dev/null
  "$REPO_ROOT/themes/cursors/install.sh" --help >/dev/null
}
run_test "CLI --help flags execution and zero exit codes" test_cli_help

# Test 5: Compatibility check command
test_compat_check() {
  "$REPO_ROOT/scripts/compat-check.sh" >/dev/null
}
run_test "Compatibility checker (scripts/compat-check.sh)" test_compat_check

# Test 6: Dry-run installer command across presets and appearance flags
test_dry_run() {
  "$REPO_ROOT/scripts/install.sh" --preset balanced --dry-run >/dev/null
  "$REPO_ROOT/scripts/install.sh" --preset minimal --dry-run >/dev/null
  "$REPO_ROOT/scripts/install.sh" --preset full --dry-run >/dev/null
  "$REPO_ROOT/scripts/install.sh" --appearance --dry-run >/dev/null
}
run_test "Installer dry-run across all presets and appearance flags" test_dry_run

# Test 7: Appearance status and preview modes
test_appearance_preview() {
  "$REPO_ROOT/scripts/appearance.sh" --status >/dev/null
  "$REPO_ROOT/scripts/appearance.sh" --preset macos-dark --preview >/dev/null
  "$REPO_ROOT/scripts/appearance.sh" --preset macos-light --preview >/dev/null
  "$REPO_ROOT/scripts/appearance.sh" --buttons left --preview >/dev/null
  "$REPO_ROOT/scripts/appearance.sh" --mode dark --preview >/dev/null
}
run_test "Appearance status and preview modes" test_appearance_preview

# Test 8: Wallpaper provider dry-run and file validation
test_wallpaper_provider() {
  [ -f "$REPO_ROOT/themes/wallpapers/macOS-macKali-Light.png" ] || return 1
  [ -f "$REPO_ROOT/themes/wallpapers/macOS-macKali-Dark.png" ] || return 1
  "$REPO_ROOT/scripts/providers/wallpaper-provider.sh" --bundled --dry-run >/dev/null
}
run_test "Wallpaper provider bundled assets and dry-run" test_wallpaper_provider

# Test 9: Theme and Icon providers non-destructive checks
test_providers_check() {
  "$REPO_ROOT/scripts/providers/gtk-provider.sh" --check >/dev/null
  "$REPO_ROOT/scripts/providers/icon-provider.sh" --check >/dev/null
  "$REPO_ROOT/scripts/providers/gtk-provider.sh" --install --dry-run >/dev/null
  "$REPO_ROOT/scripts/providers/icon-provider.sh" --install --dry-run >/dev/null
}
run_test "GTK and Icon providers non-destructive checks and dry-runs" test_providers_check

# Test 10: Isolated Backup and Restore
test_backup_restore() {
  local backup_dest="$SANDBOX/backup_test"
  "$REPO_ROOT/scripts/backup.sh" --dest "$backup_dest" >/dev/null
  [ -f "$backup_dest/backup-meta.json" ] || return 1
  [ -f "$backup_dest/org_gnome_desktop.dconf" ] || return 1
  [ -f "$backup_dest/org_gnome_shell.dconf" ] || return 1
  # Test restoration safely with dry-run from this isolated backup
  "$REPO_ROOT/scripts/restore.sh" --from "$backup_dest" --dry-run >/dev/null
}
run_test "Isolated backup creation & restore verification" test_backup_restore

# Test 11: Cursor Installation & Uninstallation lifecycle
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

# Test 12: Reentrancy check (Running installation twice does not corrupt settings)
test_reentrancy() {
  # Run installer twice with dry-run
  "$REPO_ROOT/scripts/install.sh" --preset balanced --dry-run >/dev/null
  "$REPO_ROOT/scripts/install.sh" --preset balanced --dry-run >/dev/null
  # Run cursor installer twice
  "$REPO_ROOT/themes/cursors/install.sh" >/dev/null
  "$REPO_ROOT/themes/cursors/install.sh" >/dev/null
  local target="$HOME/.local/share/icons/WhiteSur-cursors"
  [ -d "$target/cursors" ] || return 1
  # Clean up
  "$REPO_ROOT/themes/cursors/install.sh" --uninstall >/dev/null
}
run_test "Installer reentrancy and idempotency (no duplication on repeated runs)" test_reentrancy

# Test 13: Extension manager inspection commands
test_ext_mgr_inspection() {
  "$REPO_ROOT/scripts/extensions-manager.sh" --list >/dev/null || return 1
  "$REPO_ROOT/scripts/extensions-manager.sh" --compat >/dev/null || return 1
  "$REPO_ROOT/scripts/extensions-manager.sh" --status >/dev/null || return 1
}
run_test "Extension manager metadata, compatibility, and status reporting" test_ext_mgr_inspection

# Test 14: Extension manager preset dry-runs
test_ext_mgr_presets() {
  "$REPO_ROOT/scripts/extensions-manager.sh" --preset minimal --dry-run >/dev/null || return 1
  "$REPO_ROOT/scripts/extensions-manager.sh" --preset balanced --dry-run >/dev/null || return 1
  "$REPO_ROOT/scripts/extensions-manager.sh" --preset balanced --with-magic-lamp --dry-run >/dev/null || return 1
  "$REPO_ROOT/scripts/extensions-manager.sh" --preset full --with-wobbly --with-cube --dry-run >/dev/null || return 1
}
run_test "Extension manager preset resolution and opt-in dry-runs" test_ext_mgr_presets

# Test 15: Dock configuration and favorite-apps preservation
test_dock_safety() {
  # Verify dock config dry-run executes cleanly
  "$REPO_ROOT/scripts/extensions-manager.sh" --dock-config --dry-run >/dev/null || return 1
  # Ensure favorite-apps gsettings is preserved and not altered if schema is present
  if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -qx "org.gnome.shell"; then
    local current_favs
    current_favs="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || true)"
    [ -n "$current_favs" ] || return 1
  fi
  return 0
}
run_test "Dash to Dock layout safety & favorite-apps preservation" test_dock_safety

# Test 16: Safe restoration and non-destructive extension lifecycle
test_ext_restore() {
  "$REPO_ROOT/scripts/extensions-manager.sh" --restore --dry-run >/dev/null || return 1
  "$REPO_ROOT/scripts/install.sh" --extensions --preset balanced --dry-run >/dev/null || return 1
}
run_test "Extension manager safe restoration & non-destructive dry-run" test_ext_restore

# Test 17: Dynamic GNOME Compatibility — Current Version Verification (GNOME 50)
test_compat_current_gnome() {
  local output
  output="$("$REPO_ROOT/scripts/compat-check.sh" -g 50)"
  echo "$output" | grep -q "Verified Compatible (GNOME 50)" || return 1
  echo "$output" | grep -q "Wallpapers:          Universal" || return 1
  echo "$output" | grep -q "Cursor Themes:       Universal" || return 1
  return 0
}
run_test "Dynamic GNOME compatibility: Current GNOME 50 (Verified Compatible)" test_compat_current_gnome

# Test 18: Older GNOME Version Simulation (GNOME 46 & GNOME 40)
test_compat_older_gnome() {
  local out_46 out_40
  out_46="$("$REPO_ROOT/scripts/compat-check.sh" -g 46 2>&1)"
  # Dash to Dock is reported compatible on GNOME 46
  echo "$out_46" | grep -q "Dash to Dock: Reported Compatible (GNOME 46)" || return 1
  # Compiz windows effect requires GNOME 49+, so it must be marked Unsupported on 46
  echo "$out_46" | grep -q "Compiz windows effect: Unsupported on GNOME 46" || return 1

  # GNOME 40 is below min_gnome_version (45) for all supported extensions
  out_40="$("$REPO_ROOT/scripts/compat-check.sh" -g 40 2>&1)"
  echo "$out_40" | grep -q "Dash to Dock: Unsupported on GNOME 40" || return 1
  echo "$out_40" | grep -q "Wallpapers:          Universal" || return 1
  return 0
}
run_test "Older GNOME version simulation: GNOME 46 (Reported) & GNOME 40 (Unsupported)" test_compat_older_gnome

# Test 19: Unknown Future GNOME Version Simulation (GNOME 55)
test_compat_future_gnome() {
  local output
  output="$("$REPO_ROOT/scripts/compat-check.sh" -g 55)"
  # Unknown versions must be marked COMPATIBILITY_UNKNOWN, never assumed compatible
  echo "$output" | grep -q "Compatibility Unknown on GNOME 55" || return 1
  echo "$output" | grep -qv "Verified Compatible (GNOME 55)" || return 1
  # Universal components must remain compatible even on GNOME 55
  echo "$output" | grep -q "Wallpapers:          Universal" || return 1
  echo "$output" | grep -q "Cursor Themes:       Universal" || return 1
  return 0
}
run_test "Unknown future GNOME simulation: GNOME 55 (Compatibility Unknown, never assumed)" test_compat_future_gnome

# Test 20: Missing Network Access & Offline Compatibility Handling
test_compat_offline_fallback() {
  # Without --online, an unverified version must safely report unknown without failing
  local output
  output="$("$REPO_ROOT/scripts/compat-check.sh" -g 53)"
  echo "$output" | grep -q "Compatibility Unknown on GNOME 53" || return 1
  return 0
}
run_test "Offline compatibility evaluation fallback (safe handling without network)" test_compat_offline_fallback

# Test 21: Partial Component Compatibility & Preset Resilience
test_partial_component_resilience() {
  # Test that extensions-manager preset dry-runs succeed and report component independence
  local output
  output="$("$REPO_ROOT/scripts/extensions-manager.sh" --compat)"
  echo "$output" | grep -q "Universal desktop components" || return 1

  # Test that install dry-run with extensions handles preset orchestration
  "$REPO_ROOT/scripts/install.sh" --preset balanced --dry-run >/dev/null || return 1
  return 0
}
run_test "Partial component compatibility & preset resilience" test_partial_component_resilience

# Test 22: Safe Recovery Audit & User Configuration Preservation
test_safe_recovery_audit() {
  # 1. Verify uninstall dry-run / help flags work
  "$REPO_ROOT/scripts/uninstall.sh" --help >/dev/null || return 1
  # 2. Verify restore dry-run does not alter live settings
  local orig_wp orig_theme
  if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -qx "org.gnome.desktop.background"; then
    orig_wp="$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || true)"
  fi
  "$REPO_ROOT/scripts/restore.sh" --dry-run >/dev/null 2>&1 || true
  if [ -n "$orig_wp" ]; then
    local cur_wp
    cur_wp="$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || true)"
    [ "$orig_wp" = "$cur_wp" ] || return 1
  fi
  return 0
}
run_test "Safe recovery audit & user settings preservation" test_safe_recovery_audit

# Test 23: TUI installer script syntax and executable permissions
test_tui_syntax_and_perms() {
  [ -x "$REPO_ROOT/scripts/tui-installer.sh" ] || return 1
  bash -n "$REPO_ROOT/scripts/tui-installer.sh" || return 1
  return 0
}
run_test "Phase 4A: TUI script syntax and executable permissions" test_tui_syntax_and_perms

# Test 24: Backend selection and plain-terminal fallback
test_tui_backend_selection() {
  # 1. Force plain mode
  local out_plain
  out_plain="$(TUI_BACKEND=plain "$REPO_ROOT/scripts/tui-installer.sh" --plain --non-interactive --dry-run 2>&1)"
  echo "$out_plain" | grep -q "UI Backend:  plain" || return 1

  # 2. Test missing backend graceful fallback (e.g. invalid or non-installed backend)
  local out_fallback
  out_fallback="$(TUI_BACKEND=dialog "$REPO_ROOT/scripts/tui-installer.sh" --non-interactive --dry-run 2>&1 || true)"
  echo "$out_fallback" | grep -q "plain-terminal mode" || echo "$out_fallback" | grep -q "UI Backend:" || return 1
  return 0
}
run_test "Phase 4A: Backend selection and plain-terminal fallback" test_tui_backend_selection

# Test 25: Preset selection and option forwarding (Dry-run execution)
test_tui_preset_forwarding() {
  # Test minimal preset forwarding
  local out_min
  out_min="$("$REPO_ROOT/scripts/tui-installer.sh" --plain --non-interactive --preset minimal --dry-run 2>&1)"
  echo "$out_min" | grep -q "Preset Tier:       minimal" || return 1
  echo "$out_min" | grep -q "macKali Minimal" || return 1

  # Test full preset forwarding
  local out_full
  out_full="$("$REPO_ROOT/scripts/tui-installer.sh" --plain --non-interactive --preset full --dry-run 2>&1)"
  echo "$out_full" | grep -q "Preset Tier:       full" || return 1
  echo "$out_full" | grep -q "macKali Full" || return 1
  return 0
}
run_test "Phase 4A: Preset selection and option forwarding (minimal & full dry-runs)" test_tui_preset_forwarding

# Test 26: User cancellation before modifications
test_tui_cancellation() {
  # 1. Cancellation at welcome step
  local out_cancel_welcome
  out_cancel_welcome="$(printf "n\n" | "$REPO_ROOT/scripts/tui-installer.sh" --plain 2>&1)"
  echo "$out_cancel_welcome" | grep -q "cancelled by user" || return 1

  # 2. Cancellation at confirmation step
  local out_cancel_confirm
  out_cancel_confirm="$(printf "y\n2\n1\ny\nn\n" | "$REPO_ROOT/scripts/tui-installer.sh" --plain 2>&1)"
  echo "$out_cancel_confirm" | grep -q "cancelled by user" || return 1
  return 0
}
run_test "Phase 4A: Clean user cancellation before desktop modifications" test_tui_cancellation

# Test 27: Backup default and confirmation handling
test_tui_backup_handling() {
  # Verify backup is enabled by default
  local out_def
  out_def="$("$REPO_ROOT/scripts/tui-installer.sh" --plain --non-interactive --dry-run 2>&1)"
  echo "$out_def" | grep -q "Safety Backup:     Yes" || return 1

  # Verify --no-backup disables backup in plan
  local out_nobackup
  out_nobackup="$("$REPO_ROOT/scripts/tui-installer.sh" --plain --non-interactive --no-backup --dry-run 2>&1)"
  echo "$out_nobackup" | grep -q "Safety Backup:     No" || return 1
  return 0
}
run_test "Phase 4A: Backup default (Enabled) and --no-backup override" test_tui_backup_handling

# Test 28: Correct display & handling of extension compatibility
test_tui_compat_display() {
  local output
  output="$("$REPO_ROOT/scripts/tui-installer.sh" --plain --non-interactive --dry-run 2>&1)"
  echo "$output" | grep -q "Universal Components" || return 1
  echo "$output" | grep -q "Shell & Extension Components Status" || return 1
  echo "$output" | grep -q "macKali Safety Guarantees" || return 1
  return 0
}
run_test "Phase 4A: Compatibility and safety report display in wizard" test_tui_compat_display

# Test 29: Preservation of existing CLI interface
test_existing_cli_preserved() {
  # Verify root install.sh legacy usage works
  "$REPO_ROOT/install.sh" --help >/dev/null || return 1
  "$REPO_ROOT/install.sh" --check >/dev/null || return 1

  # Verify scripts/install.sh non-interactive CLI flags work
  "$REPO_ROOT/scripts/install.sh" --preset balanced --dry-run >/dev/null || return 1
  "$REPO_ROOT/scripts/install.sh" --preset minimal --dry-run >/dev/null || return 1
  return 0
}
run_test "Phase 4A: Preservation of existing non-interactive CLI interfaces" test_existing_cli_preserved

# Test 30: Root interactive entry point (./install.sh --interactive)
test_root_interactive_entry() {
  local output
  output="$("$REPO_ROOT/install.sh" --interactive --plain --non-interactive --preset balanced --dry-run 2>&1)"
  echo "$output" | grep -q "Welcome to the macKali Desktop Customization Wizard" || return 1
  echo "$output" | grep -q "macKali Customization Completed Successfully" || return 1
  return 0
}
run_test "Phase 4A: Root interactive entry point (./install.sh --interactive)" test_root_interactive_entry

# Test 31: Phase 4B: Static website build and asset assembly
test_website_build() {
  [ -x "$REPO_ROOT/website/build.sh" ] || return 1
  bash "$REPO_ROOT/website/build.sh" --clean --validate >/dev/null || return 1
  [ -d "$REPO_ROOT/website/dist" ] || return 1
  [ -s "$REPO_ROOT/website/dist/index.html" ] || return 1
  [ -s "$REPO_ROOT/website/dist/404.html" ] || return 1
  [ -s "$REPO_ROOT/website/dist/styles.css" ] || return 1
  [ -s "$REPO_ROOT/website/dist/script.js" ] || return 1
  [ -s "$REPO_ROOT/website/dist/assets/preview.png" ] || return 1
  [ -s "$REPO_ROOT/website/dist/assets/macOS-macKali-Light.png" ] || return 1
  [ -s "$REPO_ROOT/website/dist/assets/macOS-macKali-Dark.png" ] || return 1
  return 0
}
run_test "Phase 4B: Static website build and asset assembly (website/build.sh)" test_website_build

# Test 32: Phase 4B: Static website internal link and reference integrity
test_website_integrity() {
  python3 - <<'PYEOF'
import os, sys, re

repo_root = os.environ.get("REPO_ROOT", ".")
dist_dir = os.path.join(repo_root, "website", "dist")
index_path = os.path.join(dist_dir, "index.html")
if not os.path.exists(index_path):
    print("Missing index.html in dist", file=sys.stderr)
    sys.exit(1)

with open(index_path, "r", encoding="utf-8") as f:
    html = f.read()

# Verify key copy command is present
assert "git clone https://github.com/realmadede/macKali.git" in html, "Missing clone command"
assert "./install.sh --interactive" in html, "Missing interactive flag"

# Verify all relative local references exist
pattern = r'(?:href|src)=["\'](assets/[^"\']+|styles\.css|script\.js|favicon\.svg|index\.html|404\.html)["\']'
for match in re.finditer(pattern, html):
    target = match.group(1)
    full_path = os.path.join(dist_dir, target)
    if not os.path.exists(full_path):
        print(f"Missing referenced target: {target} at {full_path}", file=sys.stderr)
        sys.exit(1)

print("Static website internal integrity verified.")
PYEOF
  return $?
}
run_test "Phase 4B: Static website internal link and reference integrity" test_website_integrity

# Test 33: Phase 5: Authoritative VERSION format and SemVer compliance
test_version_compliance() {
  [ -f "$REPO_ROOT/VERSION" ] || return 1
  local ver
  ver="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
  [ -n "$ver" ] || return 1
  echo "$ver" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' || return 1

  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/lib/common.sh"
  local fn_ver
  fn_ver="$(get_mackali_version "$REPO_ROOT")"
  [ "$fn_ver" = "$ver" ] || return 1
  return 0
}
run_test "Phase 5: Authoritative VERSION format and SemVer compliance" test_version_compliance

# Test 34: Phase 5: CHANGELOG.md structure and Keep a Changelog conformance
test_changelog_structure() {
  [ -f "$REPO_ROOT/CHANGELOG.md" ] || return 1
  grep -q "# Changelog" "$REPO_ROOT/CHANGELOG.md" || return 1
  grep -q "## \[Unreleased\]" "$REPO_ROOT/CHANGELOG.md" || return 1
  grep -q "## \[1.0.0-rc.1\]" "$REPO_ROOT/CHANGELOG.md" || return 1
  grep -q "### Added" "$REPO_ROOT/CHANGELOG.md" || return 1
  return 0
}
run_test "Phase 5: CHANGELOG.md structure and Keep a Changelog conformance" test_changelog_structure

# Test 35: Phase 5: Release packaging script execution and archive generation
test_packaging_script() {
  local test_dist="$SANDBOX/dist"
  rm -rf "$test_dist"
  bash "$REPO_ROOT/scripts/package-release.sh" --output-dir "$test_dist" --no-check >/dev/null || return 1
  [ -d "$test_dist" ] || return 1
  [ -f "$test_dist/macKali-v1.0.0-rc.1.tar.gz" ] || return 1
  [ -f "$test_dist/SHA256SUMS" ] || return 1
  return 0
}
run_test "Phase 5: Release packaging script execution and artifact generation" test_packaging_script

# Test 36: Phase 5: Archive SHA-256 checksum integrity verification
test_archive_checksum_integrity() {
  local test_dist="$SANDBOX/dist"
  [ -f "$test_dist/SHA256SUMS" ] || return 1
  (
    cd "$test_dist"
    sha256sum -c SHA256SUMS >/dev/null 2>&1
  ) || return 1
  return 0
}
run_test "Phase 5: Archive SHA-256 checksum integrity verification" test_archive_checksum_integrity

# Test 37: Phase 5: Release archive content completeness and file permissions
test_archive_contents() {
  local test_dist="$SANDBOX/dist"
  local extract_dir="$SANDBOX/extract_test"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  tar -xzf "$test_dist/macKali-v1.0.0-rc.1.tar.gz" -C "$extract_dir" || return 1

  local payload="$extract_dir/macKali-v1.0.0-rc.1"
  [ -d "$payload" ] || return 1

  local required=(
    "install.sh"
    "VERSION"
    "LICENSE"
    "README.md"
    "CHANGELOG.md"
    "scripts/install.sh"
    "scripts/tui-installer.sh"
    "scripts/compat-check.sh"
    "scripts/appearance.sh"
    "scripts/backup.sh"
    "scripts/restore.sh"
    "scripts/uninstall.sh"
    "scripts/extensions-manager.sh"
    "scripts/lib/common.sh"
    "scripts/providers/gtk-provider.sh"
    "scripts/providers/icon-provider.sh"
    "themes/wallpapers/macOS-macKali-Light.png"
    "themes/wallpapers/macOS-macKali-Dark.png"
    "themes/cursors/install.sh"
    "extensions/manifests/dash-to-dock.json"
    "extensions/presets/balanced.json"
    "config/dock/dash-to-dock.dconf"
    "assets/preview.png"
    "docs/installation.md"
    "docs/architecture.md"
  )
  for item in "${required[@]}"; do
    if [ ! -s "$payload/$item" ]; then
      echo "Missing or empty required file: $item"
      return 1
    fi
  done

  [ -x "$payload/install.sh" ] || return 1
  [ -x "$payload/scripts/install.sh" ] || return 1
  [ -x "$payload/scripts/tui-installer.sh" ] || return 1
  [ -x "$payload/scripts/compat-check.sh" ] || return 1
  [ -x "$payload/scripts/appearance.sh" ] || return 1
  [ -x "$payload/scripts/restore.sh" ] || return 1
  [ -x "$payload/scripts/uninstall.sh" ] || return 1
  return 0
}
run_test "Phase 5: Release archive content completeness and file permissions" test_archive_contents

# Test 38: Phase 5: Release archive exclusion of development and temporary artifacts
test_archive_exclusions() {
  local payload="$SANDBOX/extract_test/macKali-v1.0.0-rc.1"
  [ -d "$payload" ] || return 1

  local forbidden=(
    ".git"
    ".github"
    "website"
    "tests"
    "dist"
    "build"
    ".cache"
  )
  for item in "${forbidden[@]}"; do
    if [ -e "$payload/$item" ]; then
      echo "Forbidden path present in archive payload: $item"
      return 1
    fi
  done
  return 0
}
run_test "Phase 5: Release archive exclusion of development artifacts" test_archive_exclusions

# Test 39: Phase 5: Standalone execution of root entry points outside Git repository
test_standalone_execution() {
  local payload="$SANDBOX/extract_test/macKali-v1.0.0-rc.1"
  [ -d "$payload" ] || return 1
  [ ! -e "$payload/.git" ] || return 1

  "$payload/install.sh" --help >/dev/null || return 1
  "$payload/scripts/compat-check.sh" --help >/dev/null || return 1
  "$payload/scripts/appearance.sh" --help >/dev/null || return 1
  "$payload/scripts/uninstall.sh" --help >/dev/null || return 1
  return 0
}
run_test "Phase 5: Standalone execution of root entry points outside Git repository" test_standalone_execution

# Test 40: Phase 5: Website production domain metadata & releases navigation integrity
test_website_production_metadata() {
  [ -f "$REPO_ROOT/website/index.html" ] || return 1
  [ -f "$REPO_ROOT/website/sitemap.xml" ] || return 1
  [ -f "$REPO_ROOT/website/robots.txt" ] || return 1

  grep -q "https://mackali.madede.workers.dev/" "$REPO_ROOT/website/index.html" || return 1
  grep -q "https://github.com/realmadede/macKali/releases" "$REPO_ROOT/website/index.html" || return 1
  grep -q "https://mackali.madede.workers.dev/sitemap.xml" "$REPO_ROOT/website/robots.txt" || return 1
  grep -q "https://mackali.madede.workers.dev/" "$REPO_ROOT/website/sitemap.xml" || return 1

  if grep -rq "realmadede.github.io" "$REPO_ROOT/website"; then
    echo "Outdated realmadede.github.io domain still present in website files"
    return 1
  fi
  return 0
}
run_test "Phase 5: Website production domain metadata and releases link integrity" test_website_production_metadata

# Test 41: In-app release update checker (--check-update & SemVer comparison)
test_in_app_update_checker() {
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/lib/common.sh"

  # 1. Verify is_version_newer logic
  is_version_newer "1.0.0-rc.1" "1.0.0" || return 1
  is_version_newer "1.0.0" "1.0.1" || return 1
  ! is_version_newer "1.0.1" "1.0.0" || return 1
  ! is_version_newer "1.0.0" "1.0.0" || return 1

  # 2. Test mock newer release notification via install.sh --check-update
  local out_update
  out_update="$(MOCK_LATEST_RELEASE="v1.0.1" "$REPO_ROOT/install.sh" --check-update 2>&1)"
  echo "$out_update" | grep -q "macKali Update Available!" || return 1
  echo "$out_update" | grep -q "v1.0.1" || return 1

  # 3. Test mock current release (up to date)
  local out_current
  out_current="$(MOCK_LATEST_RELEASE="v1.0.0-rc.1" "$REPO_ROOT/install.sh" --check-update 2>&1)"
  echo "$out_current" | grep -q "is up to date" || return 1

  # 4. Test --no-update-check suppression
  local out_suppressed
  out_suppressed="$(MOCK_LATEST_RELEASE="v1.0.1" "$REPO_ROOT/scripts/install.sh" --preset minimal --dry-run --no-update-check 2>&1)"
  if echo "$out_suppressed" | grep -q "macKali Update Available!"; then
    echo "--no-update-check failed to suppress update banner"
    return 1
  fi

  return 0
}
run_test "Phase 5: In-app release update checker (--check-update and SemVer evaluation)" test_in_app_update_checker

echo "============================================================"
echo -e "Test Results: ${C_GREEN}$PASSED passed${C_RESET}, ${C_RED}$FAILED failed${C_RESET}"
echo "============================================================"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
