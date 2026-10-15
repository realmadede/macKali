#!/usr/bin/env bash
# macKali GTK & GNOME Shell Theme Provider
# Handles user-level installation and verification of WhiteSur GTK & Shell themes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/common.sh"

THEME_DIR="$HOME/.local/share/themes"
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"
UPSTREAM_REPO="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
DRY_RUN=false
ACTION="check"

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
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      echo "macKali GTK & Shell Theme Provider"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --check       Check if WhiteSur GTK themes are installed"
      echo "  --install     Install WhiteSur GTK & Shell themes to ~/.local/share/themes"
      echo "  --uninstall   Remove installed WhiteSur themes"
      echo "  --dry-run     Preview operations without writing files"
      echo "  -h, --help    Show this help message"
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
  for theme in WhiteSur-Dark WhiteSur-Light WhiteSur-Dark-solid WhiteSur-Light-solid; do
    if [ -d "$THEME_DIR/$theme" ] || [ -d "/usr/share/themes/$theme" ]; then
      log_success "Found theme: $theme"
      found=true
    fi
  done
  if [ "$found" = false ]; then
    log_info "No WhiteSur GTK themes currently installed."
    return 1
  fi
  return 0
}

case "$ACTION" in
  check)
    log_step "Checking for installed WhiteSur GTK & Shell themes..."
    check_installed || true
    ;;

  install)
    log_step "Installing WhiteSur GTK & Shell themes..."
    if [ "$DRY_RUN" = true ]; then
      log_info "[DRY-RUN] Would clone $UPSTREAM_REPO (depth 1) into temporary build directory."
      log_info "[DRY-RUN] Would execute upstream user-level installer to ~/.local/share/themes."
      log_info "[DRY-RUN] Would track installed theme directories in $MANIFEST_FILE."
      exit 0
    fi

    if ! has_cmd git; then
      log_error "git is required to fetch WhiteSur GTK theme repository."
      exit 1
    fi

    TMP_DIR="$(mktemp -d /tmp/whitesur-gtk-XXXXXX)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    log_info "Cloning WhiteSur GTK theme repository (shallow clone)..."
    git clone --depth 1 "$UPSTREAM_REPO" "$TMP_DIR/repo"

    log_info "Running user-level theme installer (dest: $THEME_DIR)..."
    mkdir -p "$THEME_DIR"
    (
      cd "$TMP_DIR/repo"
      # Run user-level install into ~/.local/share/themes without touching root
      ./install.sh -d "$THEME_DIR" -t default -N glassy -s standard
    )

    for theme in WhiteSur-Dark WhiteSur-Light WhiteSur-Dark-solid WhiteSur-Light-solid; do
      if [ -d "$THEME_DIR/$theme" ]; then
        track_installed_dir "$THEME_DIR/$theme"
      fi
    done

    log_success "WhiteSur GTK & Shell themes installed to $THEME_DIR"
    ;;

  uninstall)
    log_step "Removing WhiteSur GTK & Shell themes..."
    for theme in WhiteSur-Dark WhiteSur-Light WhiteSur-Dark-solid WhiteSur-Light-solid; do
      if [ -d "$THEME_DIR/$theme" ]; then
        if [ "$DRY_RUN" = true ]; then
          log_info "[DRY-RUN] Would delete: $THEME_DIR/$theme"
        else
          rm -rf "$THEME_DIR/$theme"
          log_success "Removed: $THEME_DIR/$theme"
        fi
      fi
    done
    ;;
esac
