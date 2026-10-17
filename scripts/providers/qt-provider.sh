#!/usr/bin/env bash
# macKali Qt / Kvantum Theme Provider
# Handles user-space installation, verification, and configuration of macOS / WhiteSur Qt themes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/common.sh"

KVANTUM_DIR="$HOME/.config/Kvantum"
KVANTUM_CONF="$KVANTUM_DIR/kvantum.kvconfig"
ENVIRONMENT_DIR="$HOME/.config/environment.d"
QT_ENV_CONF="$ENVIRONMENT_DIR/10-mackali-qt.conf"
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"
UPSTREAM_REPO="https://github.com/vinceliuice/WhiteSur-kde.git"
DRY_RUN=false
ACTION="check"
THEME_NAME="WhiteSurDark"

track_installed_dir() {
  local dpath="$1"
  mkdir -p "$(dirname "$MANIFEST_FILE")"
  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "[]" > "$MANIFEST_FILE"
  fi
  if has_cmd jq; then
    local tmp
    tmp="$(mktemp)"
    jq --arg d "$dpath" '. += [$d] | unique' "$MANIFEST_FILE" > "$tmp" && mv "$tmp" "$MANIFEST_FILE"
  fi
}

track_installed_file() {
  local fpath="$1"
  mkdir -p "$(dirname "$MANIFEST_FILE")"
  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "[]" > "$MANIFEST_FILE"
  fi
  if has_cmd jq; then
    local tmp
    tmp="$(mktemp)"
    jq --arg f "$fpath" '. += [$f] | unique' "$MANIFEST_FILE" > "$tmp" && mv "$tmp" "$MANIFEST_FILE"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      ACTION="install"
      shift
      ;;
    --check)
      ACTION="check"
      shift
      ;;
    --uninstall)
      ACTION="uninstall"
      shift
      ;;
    --theme)
      case "$2" in
        dark|WhiteSurDark) THEME_NAME="WhiteSurDark" ;;
        light|WhiteSur) THEME_NAME="WhiteSur" ;;
        *) THEME_NAME="$2" ;;
      esac
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      echo "macKali Qt & Kvantum Theme Provider"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --check              Check if Kvantum and WhiteSur Qt themes are configured"
      echo "  --install            Install WhiteSur Qt themes and configure environment"
      echo "  --uninstall          Remove installed WhiteSur Qt themes and configuration"
      echo "  --theme [dark|light] Select Qt theme variant (default: dark)"
      echo "  --dry-run            Preview operations without writing files"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

check_installed() {
  local found=false
  for theme in WhiteSurDark WhiteSur; do
    if [ -d "$KVANTUM_DIR/$theme" ] || [ -d "/usr/share/Kvantum/$theme" ]; then
      log_success "Found Kvantum theme: $theme"
      found=true
    fi
  done
  if has_cmd kvantummanager || has_cmd kvantumpreview; then
    log_success "Found Kvantum engine in system PATH"
  else
    log_info "Kvantum engine not installed (install via: sudo apt install qt6-style-kvantum qt5-style-kvantum)"
  fi
  if [ "$found" = false ]; then
    log_info "No WhiteSur Kvantum themes currently installed in $KVANTUM_DIR."
    return 1
  fi
  return 0
}

case "$ACTION" in
  check)
    log_step "Checking for installed WhiteSur Qt & Kvantum themes..."
    check_installed || true
    ;;

  install)
    log_step "Configuring WhiteSur Qt & Kvantum integration ($THEME_NAME)..."
    if [ "$DRY_RUN" = true ]; then
      log_info "[DRY-RUN] Would create directory: $KVANTUM_DIR"
      log_info "[DRY-RUN] Would install WhiteSur Kvantum theme definitions ($THEME_NAME)"
      log_info "[DRY-RUN] Would write active theme to $KVANTUM_CONF"
      log_info "[DRY-RUN] Would configure session environment in $QT_ENV_CONF (QT_STYLE_OVERRIDE=kvantum, QT_QPA_PLATFORM=xcb)"
      exit 0
    fi

    mkdir -p "$KVANTUM_DIR"
    mkdir -p "$ENVIRONMENT_DIR"

    # Install bundled or template WhiteSur Kvantum configuration if available
    mkdir -p "$KVANTUM_DIR/$THEME_NAME"
    if [ "$THEME_NAME" = "WhiteSur" ] && [ -f "/usr/share/Kvantum/KvMojaveLight/KvMojaveLight.kvconfig" ]; then
      cp "/usr/share/Kvantum/KvMojaveLight/KvMojaveLight.kvconfig" "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig"
      cp "/usr/share/Kvantum/KvMojaveLight/KvMojaveLight.svg" "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg"
      track_installed_file "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg"
    elif [ "$THEME_NAME" = "WhiteSurDark" ] && [ -f "/usr/share/Kvantum/KvMojave/KvMojave.kvconfig" ]; then
      cp "/usr/share/Kvantum/KvMojave/KvMojave.kvconfig" "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig"
      cp "/usr/share/Kvantum/KvMojave/KvMojave.svg" "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg"
      track_installed_file "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg"
    else
      cat <<EOF > "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig"
[General]
theme=$THEME_NAME
author=Vince Liuice
comment=macOS inspired theme for Kvantum

[Hacks]
transparent_dolphin_view=true
blurring=true
EOF
    fi
    track_installed_file "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig"
    track_installed_dir "$KVANTUM_DIR/$THEME_NAME"

    # Set active Kvantum theme
    cat <<EOF > "$KVANTUM_CONF"
[General]
theme=$THEME_NAME
EOF
    track_installed_file "$KVANTUM_CONF"

    # Configure session environment for Qt apps
    cat <<EOF > "$QT_ENV_CONF"
# macKali Qt / Kvantum session configuration
QT_STYLE_OVERRIDE=kvantum
QT_QPA_PLATFORM=xcb
EOF
    track_installed_file "$QT_ENV_CONF"

    log_success "WhiteSur Qt & Kvantum theme configured with theme: $THEME_NAME"
    log_info "Environment written to $QT_ENV_CONF"
    ;;

  uninstall)
    log_step "Removing WhiteSur Qt & Kvantum configuration..."
    for theme in WhiteSurDark WhiteSur; do
      if [ -d "$KVANTUM_DIR/$theme" ]; then
        if [ "$DRY_RUN" = true ]; then
          log_info "[DRY-RUN] Would delete: $KVANTUM_DIR/$theme"
        else
          rm -rf "${KVANTUM_DIR:?}/$theme"
          log_success "Removed: $KVANTUM_DIR/$theme"
        fi
      fi
    done
    if [ -f "$QT_ENV_CONF" ]; then
      if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would remove: $QT_ENV_CONF"
      else
        rm -f "$QT_ENV_CONF"
        log_success "Removed: $QT_ENV_CONF"
      fi
    fi
    if [ -f "$KVANTUM_CONF" ]; then
      if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would remove active theme from: $KVANTUM_CONF"
      else
        rm -f "$KVANTUM_CONF"
        log_success "Removed: $KVANTUM_CONF"
      fi
    fi
    ;;
esac
