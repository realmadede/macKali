#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common helpers
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

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

echo ""
# 3. GNOME Extension Compatibility Check
log_step "Evaluating GNOME Extension Compatibility Matrix..."
MANIFEST_DIR="$REPO_ROOT/extensions/manifests"

if [ ! -d "$MANIFEST_DIR" ]; then
  log_error "Manifest directory not found at $MANIFEST_DIR"
  exit 1
fi

if [ "$GNOME_MAJOR_VERSION" = "0" ]; then
  log_warn "GNOME Shell not detected. Cannot match version against extension manifests."
else
  echo "Comparing target GNOME Shell major version: $GNOME_MAJOR_VERSION"
  echo ""

  for manifest in "$MANIFEST_DIR"/*.json; do
    [ -f "$manifest" ] || continue
    name="$(jq -r '.name' "$manifest")"
    uuid="$(jq -r '.uuid' "$manifest")"
    license="$(jq -r '.license // "Unknown"' "$manifest")"
    wayland_ok="$(jq -r 'if .wayland_compatible then "Wayland: Verified" else "Wayland: Unverified" end' "$manifest")"
    supported_versions="$(jq -r '.supported_gnome_versions | join(", ")' "$manifest")"
    is_compatible="$(jq --arg v "$GNOME_MAJOR_VERSION" '.supported_gnome_versions | index($v)' "$manifest")"

    if [ "$is_compatible" != "null" ]; then
      log_success "$name ($uuid) -> Compatible with GNOME $GNOME_MAJOR_VERSION ($wayland_ok, License: $license)"
    else
      log_warn "$name ($uuid) -> NOT explicitly validated for GNOME $GNOME_MAJOR_VERSION (Supports: $supported_versions)"
    fi
  done
fi

echo ""
echo "============================================================"
log_success "Compatibility check completed."
echo "============================================================"
