#!/usr/bin/env bash
# macKali Installer Engine (Phase 2: GNOME Appearance Foundation)

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
APPLY_APPEARANCE=false
APPEARANCE_MODE="dark"
APPLY_WALLPAPER=false

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
  echo -e "${COLOR_GREEN}[Phase 2: GNOME Appearance Foundation]${COLOR_RESET}"
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
    --appearance)
      APPLY_APPEARANCE=true
      shift
      ;;
    --mode)
      APPEARANCE_MODE="$2"
      shift 2
      ;;
    --wallpaper)
      APPLY_WALLPAPER=true
      shift
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
      echo "      --appearance       Apply macOS appearance (color-scheme, window buttons, wallpapers)"
      echo "      --mode [dark|light] Set appearance color mode [default: dark]"
      echo "      --wallpaper        Apply bundled 4K macOS Light & Dark wallpapers"
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
echo ""

# Report Phase 2 Scope Clearly
echo "------------------------------------------------------------"
echo "Phase 2 Component Status:"
echo "  [x] Cursors:      Ready & bundled (WhiteSur-cursors)"
echo "  [x] Wallpapers:   Ready & bundled (4K macOS Light & Dark)"
echo "  [x] Appearance:   Ready (Dark/Light mode, left traffic lights)"
echo "  [x] Providers:    Ready (GTK & Icon user-space provider engines)"
echo "  [ ] Extensions:   Decoupled from Phase 2 (appearance foundation only)"
echo "------------------------------------------------------------"
echo ""

# 1. Install Cursors
log_step "Installing WhiteSur Cursor Theme..."
if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] Would execute: $REPO_ROOT/themes/cursors/install.sh"
else
  "$REPO_ROOT/themes/cursors/install.sh"
fi

# 2. Apply Wallpaper if requested or in full preset
if [ "$APPLY_WALLPAPER" = true ] || [ "$APPLY_APPEARANCE" = true ]; then
  echo ""
  log_step "Applying macOS 4K Wallpapers..."
  if [ "$DRY_RUN" = true ]; then
    "$SCRIPT_DIR/providers/wallpaper-provider.sh" --bundled --dry-run
  else
    "$SCRIPT_DIR/providers/wallpaper-provider.sh" --bundled
  fi
fi

# 3. Apply Appearance Settings if requested
if [ "$APPLY_APPEARANCE" = true ]; then
  echo ""
  log_step "Configuring macOS Appearance..."
  PRESET_NAME="macos-dark"
  [ "$APPEARANCE_MODE" = "light" ] && PRESET_NAME="macos-light"
  if [ "$DRY_RUN" = true ]; then
    "$SCRIPT_DIR/appearance.sh" --preset "$PRESET_NAME" --preview
  else
    "$SCRIPT_DIR/appearance.sh" --preset "$PRESET_NAME" --yes
  fi
fi

echo ""
log_success "macKali installation tasks completed!"
echo ""
echo "Next Steps:"
echo "  - Check appearance status: ./scripts/appearance.sh --status"
echo "  - Revert appearance anytime: ./scripts/appearance.sh --revert"
echo "  - See manual configuration instructions: docs/manual-configuration.md"
