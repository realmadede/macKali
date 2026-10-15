#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common helpers
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

TARGET_OVERRIDE=""
ALLOW_ONLINE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gnome-version|-g)
      TARGET_OVERRIDE="$2"
      shift 2
      ;;
    --online)
      ALLOW_ONLINE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Evaluate independent component compatibility for macKali on Kali Linux."
      echo ""
      echo "Options:"
      echo "  -g, --gnome-version VER   Evaluate compatibility against a specific GNOME major version (e.g. 50, 52, 46)"
      echo "      --online              Allow live query to extensions.gnome.org API for unverified versions"
      echo "  -h, --help                Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

echo "============================================================"
echo "           macKali Environment Compatibility Check          "
echo "============================================================"

# 1. System Detection
log_step "Detecting Operating System and Environment..."
detect_os
detect_de
detect_gnome_version
detect_session_type

echo "  - Operating System:      $OS_NAME (ID: $OS_ID, Version: $OS_VERSION)"
echo "  - Desktop Environment:   $DE_NAME"
echo "  - Session Type:          $SESSION_TYPE"
echo "  - GNOME Shell Version:   $GNOME_VERSION (Major: $GNOME_MAJOR_VERSION)"

echo ""
# 2. Command & Tool Dependencies
log_step "Checking System Tool Dependencies..."

declare -A TOOLS=(
  ["gnome-shell"]="GNOME desktop shell (Required for GNOME customization)"
  ["gsettings"]="GSettings configuration tool (Required for GNOME interface)"
  ["dconf"]="dconf database backend (Required for backup and settings)"
  ["python3"]="Python 3 interpreter (Required for SVG cursor generation)"
  ["git"]="Git version control (Required for repository management)"
  ["xcursorgen"]="X11 cursor generator (Required for building cursors from source)"
  ["rsvg-convert"]="librsvg converter (Required for building cursors from source)"
)

MISSING_BUILD=()
MISSING_CORE=()

for tool in "${!TOOLS[@]}"; do
  desc="${TOOLS[$tool]}"
  if has_cmd "$tool"; then
    log_success "$tool is installed ($desc)"
  else
    if [[ "$tool" =~ ^(gnome-shell|gsettings|dconf)$ ]]; then
      log_error "$tool is MISSING - $desc"
      MISSING_CORE+=("$tool")
    else
      log_warn "$tool is NOT found - $desc"
      MISSING_BUILD+=("$tool")
    fi
  fi
done

if [ ${#MISSING_CORE[@]} -ne 0 ]; then
  echo ""
  log_warn "Critical GNOME tools are missing. macKali requires GNOME desktop components."
fi

if [ ${#MISSING_BUILD[@]} -ne 0 ]; then
  echo ""
  log_info "Note: Precompiled cursors in dist/ can be installed without build tools."
  log_info "If you plan to compile cursors from SVG source, install missing build dependencies:"
  echo "  sudo apt install -y librsvg2-bin xorg-xcursorgen python3 git"
fi

# 3. Rolling-Release Shift Check
detect_version_shift "$HOME/.config/macKali/extensions-state.json"
if [ "$VERSION_SHIFT_DETECTED" = true ]; then
  echo ""
  log_warn "GNOME Rolling Update Detected!"
  echo "  - Previous Installation Version: GNOME $RECORDED_GNOME_VER"
  echo "  - Current System Version:        GNOME $GNOME_VERSION"
  echo "  macKali will evaluate installed extension compatibility against the new environment."
fi

echo ""
# 4. Independent Component Compatibility
log_step "Evaluating Independent Component Compatibility..."

TARGET_MAJOR="${TARGET_OVERRIDE:-$GNOME_MAJOR_VERSION}"
if [ -n "$TARGET_OVERRIDE" ]; then
  echo "Target Evaluation Version (Simulated): GNOME $TARGET_MAJOR"
else
  echo "Target Evaluation Version (Active):    GNOME $TARGET_MAJOR"
fi
echo ""

echo "Universal Desktop Components (Not tied to specific GNOME Shell version):"
log_success "[1/10] Wallpapers:          Universal (Native GNOME picture-uri / picture-uri-dark pairing)"
log_success "[2/10] Cursor Themes:       Universal (Freedesktop XDG standard across Wayland & X11)"
log_success "[3/10] Icon Themes:         Universal (Freedesktop XDG icon specification)"
log_success "[4/10] GTK Themes:          Universal (Native libadwaita/GTK4 color-scheme negotiation)"

echo ""
echo "Shell & Extension Components (Version-evaluated independently):"

# Component 5: GNOME Shell User Theme
if has_cmd gnome-extensions && gnome-extensions list 2>/dev/null | grep -qx "user-theme@gnome-shell-extensions.gcampax.github.com"; then
  log_success "[5/10] GNOME Shell Themes:  Compatible (user-theme extension is available)"
else
  log_info "[5/10] GNOME Shell Themes:  Requires user-theme extension (optional)"
fi

MANIFEST_DIR="$REPO_ROOT/extensions/manifests"
EXT_COUNTER=6

declare -a TARGET_UUIDS=(
  "dash-to-dock@micxgx.gmail.com"
  "blur-my-shell@aunetx"
  "compiz-alike-magic-lamp-effect@hermes83.github.com"
  "compiz-windows-effect@hermes83.github.com"
  "desktop-cube@schneegans.github.com"
)

for uuid in "${TARGET_UUIDS[@]}"; do
  manifest=""
  case "$uuid" in
    "dash-to-dock@micxgx.gmail.com") manifest="$MANIFEST_DIR/dash-to-dock.json" ;;
    "blur-my-shell@aunetx") manifest="$MANIFEST_DIR/blur-my-shell.json" ;;
    "compiz-alike-magic-lamp-effect@hermes83.github.com") manifest="$MANIFEST_DIR/compiz-alike-magic-lamp-effect.json" ;;
    "compiz-windows-effect@hermes83.github.com") manifest="$MANIFEST_DIR/compiz-windows-effect.json" ;;
    "desktop-cube@schneegans.github.com") manifest="$MANIFEST_DIR/desktop-cube.json" ;;
  esac

  [ -f "$manifest" ] || continue
  name="$(jq -r '.name' "$manifest")"

  evaluate_extension_compat "$uuid" "$manifest" "$TARGET_MAJOR" "$ALLOW_ONLINE"

  case "$COMPAT_STATUS" in
    VERIFIED_COMPATIBLE)
      log_success "[$EXT_COUNTER/10] $name: Verified Compatible (GNOME $TARGET_MAJOR)"
      echo "         $COMPAT_DETAILS"
      ;;
    REPORTED_COMPATIBLE)
      log_info "[$EXT_COUNTER/10] $name: Reported Compatible (GNOME $TARGET_MAJOR)"
      echo "         $COMPAT_DETAILS"
      ;;
    UNSUPPORTED)
      log_error "[$EXT_COUNTER/10] $name: Unsupported on GNOME $TARGET_MAJOR"
      echo "         $COMPAT_DETAILS"
      ;;
    COMPATIBILITY_UNKNOWN)
      log_warn "[$EXT_COUNTER/10] $name: Compatibility Unknown on GNOME $TARGET_MAJOR"
      echo "         $COMPAT_DETAILS"
      ;;
  esac
  EXT_COUNTER=$((EXT_COUNTER + 1))
done

echo ""
echo "============================================================"
log_success "Independent component compatibility evaluation completed."
echo "============================================================"
