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
APPLY_APPEARANCE=true
APPEARANCE_MODE="dark"
APPLY_EXTENSIONS=false
DOCK_ONLY=false
WITH_MAGIC_LAMP=false
WITH_WOBBLY=false
WITH_CUBE=false
CHECK_UPDATES=true

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
  local ver
  ver="$(get_mackali_version "$REPO_ROOT")"
  echo -e "${COLOR_GREEN}Release v${ver}${COLOR_RESET}"
  echo ""
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --interactive|-i)
      shift
      exec "$SCRIPT_DIR/tui-installer.sh" "$@"
      ;;
    --check)
      ACTION="check"
      shift
      ;;
    --check-update|--check-updates)
      ACTION="check_update"
      shift
      ;;
    --no-update-check)
      CHECK_UPDATES=false
      shift
      ;;
    --preset)
      PRESET="$2"
      shift 2
      ;;
    --appearance|--traffic-lights)
      APPLY_APPEARANCE=true
      shift
      ;;
    --no-appearance|--no-traffic-lights)
      APPLY_APPEARANCE=false
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
    --extensions)
      APPLY_EXTENSIONS=true
      shift
      ;;
    --dock-only)
      DOCK_ONLY=true
      shift
      ;;
    --with-magic-lamp)
      WITH_MAGIC_LAMP=true
      shift
      ;;
    --with-wobbly)
      WITH_WOBBLY=true
      shift
      ;;
    --with-cube)
      WITH_CUBE=true
      shift
      ;;
    --cursors-only)
      CURSORS_ONLY=true
      APPLY_APPEARANCE=false
      APPLY_WALLPAPER=false
      APPLY_EXTENSIONS=false
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
      echo "  -i, --interactive      Run interactive terminal customization wizard (TUI)"
      echo "      --check            Run environment and GNOME compatibility checks"
      echo "      --check-update     Check official GitHub releases for newer version"
      echo "      --no-update-check  Disable automatic online release update checks"
      echo "      --preset NAME      Select preset (minimal, balanced, full) [default: balanced]"
      echo "      --appearance       Apply macOS appearance (color-scheme, window buttons, wallpapers)"
      echo "      --mode [dark|light] Set appearance color mode [default: dark]"
      echo "      --wallpaper        Apply bundled 4K macOS Light & Dark wallpapers"
      echo "      --extensions       Configure GNOME extensions corresponding to the preset"
      echo "      --dock-only        Apply only macOS-inspired bottom centered dock styling"
      echo "      --with-magic-lamp  Opt-in to Magic Lamp animation in Balanced/Full preset"
      echo "      --with-wobbly      Opt-in to Compiz wobbly windows in Full preset"
      echo "      --with-cube        Opt-in to experimental Desktop Cube in Full preset"
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

# Handle --check-update
if [ "$ACTION" = "check_update" ]; then
  check_for_updates 6 "check"
  exit 0
fi

# Run non-blocking update check notification if enabled
if [ "$CHECK_UPDATES" = true ] && [ "$ACTION" != "check" ]; then
  check_for_updates 2 "notify"
fi

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

# Report Phase 3 Scope Clearly
echo "------------------------------------------------------------"
echo "Phase 3 Component Status:"
echo "  [x] Cursors:      Ready & bundled (WhiteSur-cursors)"
echo "  [x] Wallpapers:   Ready & bundled (4K macOS Light & Dark)"
echo "  [x] Appearance:   Ready (Dark/Light mode, left traffic lights)"
echo "  [x] Providers:    Ready (GTK & Icon user-space provider engines)"
echo "  [x] Dock Layout:  Ready (macOS bottom centered layout via Dash to Dock)"
echo "  [x] Extensions:   Ready (Modular Extension Manager & verified GNOME 50 EGO releases)"
echo "------------------------------------------------------------"
echo ""

# 1. Install Cursors
log_step "Installing WhiteSur Cursor Theme..."
if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] Would execute: $REPO_ROOT/themes/cursors/install.sh"
else
  "$REPO_ROOT/themes/cursors/install.sh"
fi

# 2. Apply Wallpaper if requested
if [ "$APPLY_WALLPAPER" = true ]; then
  echo ""
  log_step "Applying macOS 4K Wallpapers..."
  if [ "$DRY_RUN" = true ]; then
    "$SCRIPT_DIR/providers/wallpaper-provider.sh" --bundled --dry-run
  else
    "$SCRIPT_DIR/providers/wallpaper-provider.sh" --bundled
  fi
fi

# 3. Apply Appearance Settings & Circular Traffic Lights
if [ "$APPLY_APPEARANCE" = true ] && [ "$CURSORS_ONLY" != true ]; then
  echo ""
  log_step "Configuring macOS Appearance & Circular Traffic Lights..."
  PRESET_NAME="macos-dark"
  [ "$APPEARANCE_MODE" = "light" ] && PRESET_NAME="macos-light"
  if [ "$DRY_RUN" = true ]; then
    "$SCRIPT_DIR/appearance.sh" --preset "$PRESET_NAME" --preview
  else
    "$SCRIPT_DIR/appearance.sh" --preset "$PRESET_NAME" --yes
  fi
fi

# 4. Apply Dock & Extensions if requested
if [ "$DOCK_ONLY" = true ]; then
  echo ""
  log_step "Applying macOS Dock Styling..."
  DOCK_CMD=("$SCRIPT_DIR/extensions-manager.sh" "--dock-config")
  [ "$DRY_RUN" = true ] && DOCK_CMD+=("--dry-run")
  "${DOCK_CMD[@]}"
elif [ "$APPLY_EXTENSIONS" = true ]; then
  echo ""
  log_step "Applying Preset Extensions ($PRESET)..."
  EXT_CMD=("$SCRIPT_DIR/extensions-manager.sh" "--preset" "$PRESET")
  [ "$DRY_RUN" = true ] && EXT_CMD+=("--dry-run")
  [ "$WITH_MAGIC_LAMP" = true ] && EXT_CMD+=("--with-magic-lamp")
  [ "$WITH_WOBBLY" = true ] && EXT_CMD+=("--with-wobbly")
  [ "$WITH_CUBE" = true ] && EXT_CMD+=("--with-cube")
  "${EXT_CMD[@]}"
fi

echo ""
log_success "macKali installation tasks completed!"
echo ""
echo "Next Steps:"
echo "  - Check extension status:  ./scripts/extensions-manager.sh --status"
echo "  - Revert dock settings:    ./scripts/extensions-manager.sh --dock-revert"
echo "  - Check appearance status: ./scripts/appearance.sh --status"
echo "  - Revert appearance:       ./scripts/appearance.sh --revert"
echo "  - Restore desktop anytime: ./scripts/restore.sh"
echo "  - Emergency safe recovery: See docs/troubleshooting.md"
echo "  - Manual configuration:    docs/manual-configuration.md"
