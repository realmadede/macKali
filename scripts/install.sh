#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

ACTION="interactive"
PRESET="balanced"
DRY_RUN=false
DO_BACKUP=false
CURSORS_ONLY=false

# Banner
print_banner() {
  echo -e "${COLOR_BOLD}${COLOR_CYAN}"
  echo "  __  __            ____  __      _ _ "
  echo " |  \/  |          |  _ \ \ \    / / |"
  echo " | \  / | __ _  ___| |_) | \ \  / /| |"
  echo " | |\/| |/ _\` |/ __|  _ <   \ \/ / | |"
  echo " | |  | | (_| | (__| |_) |   \  /  | |"
  echo " |_|  |_|\__,_|\___|____/     \/   |_|"
  echo -e "${COLOR_RESET}"
  echo -e "${COLOR_BOLD}macKali: macOS Desktop Customization for Kali Linux & GNOME${COLOR_RESET}"
  echo -e "${COLOR_YELLOW}[Phase 1: Architecture, Presets & Cursor Integration]${COLOR_RESET}"
  echo ""
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      ACTION="check"
      shift
      ;;
    --preset)
      PRESET="$2"
      shift 2
      ;;
    --cursors-only)
      CURSORS_ONLY=true
      shift
      ;;
    --backup)
      DO_BACKUP=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      print_banner
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "      --check            Run environment and GNOME compatibility checks"
      echo "      --preset NAME      Select preset (minimal, balanced, full) [default: balanced]"
      echo "      --cursors-only     Install only the WhiteSur cursor theme"
      echo "      --backup           Create a timestamped backup before installation"
      echo "      --dry-run          Preview installation operations without modifying system"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

print_banner
check_not_root

# Handle --check
if [ "$ACTION" = "check" ]; then
  exec "$SCRIPT_DIR/compat-check.sh"
fi

# Detect environment
log_step "Detecting Environment..."
detect_os
detect_de
detect_gnome_version
detect_session_type
echo "  Detected OS:     $OS_NAME"
echo "  Desktop:         $DE_NAME"
echo "  GNOME Version:   $GNOME_VERSION"
echo "  Session Type:    $SESSION_TYPE"
echo ""

# Handle backup
if [ "$DO_BACKUP" = true ]; then
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create backup via scripts/backup.sh"
  else
    "$SCRIPT_DIR/backup.sh"
    echo ""
  fi
fi

# Handle Presets
PRESET_FILE="$REPO_ROOT/extensions/presets/$PRESET.json"
if [ ! -f "$PRESET_FILE" ]; then
  log_error "Preset '$PRESET' not found at $PRESET_FILE"
  echo "Available presets: minimal, balanced, full"
  exit 1
fi

log_step "Selected Preset: $(jq -r '.name' "$PRESET_FILE")"
echo "  Description: $(jq -r '.description' "$PRESET_FILE")"
echo "  Phase 1 Status: $(jq -r '.status' "$PRESET_FILE")"
echo ""

# Report Phase 1 Scope Clearly
echo "------------------------------------------------------------"
echo "Phase 1 Component Status:"
echo "  [x] Cursors:      Ready for installation (WhiteSur-cursors)"
echo "  [ ] GTK Theme:    Planned for Phase 2 (templates in themes/gtk/)"
echo "  [ ] Shell Theme:  Planned for Phase 2 (templates in themes/shell/)"
echo "  [ ] Icons:        Planned for Phase 2 (templates in themes/icons/)"
echo "  [ ] Extensions:   Planned for Phase 2 (manifests in extensions/)"
echo "------------------------------------------------------------"
echo ""

# Install Cursors
log_step "Installing WhiteSur Cursor Theme..."
if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] Would execute: $REPO_ROOT/themes/cursors/install.sh"
else
  "$REPO_ROOT/themes/cursors/install.sh"
fi

echo ""
log_success "macKali Phase 1 installation tasks completed!"
echo ""
echo "Next Steps:"
echo "  - Verify cursor installation with: gsettings get org.gnome.desktop.interface cursor-theme"
echo "  - Review extension manifests: cat extensions/manifests/*.json"
echo "  - See manual configuration instructions: docs/manual-configuration.md"
