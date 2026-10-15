#!/usr/bin/env bash
# macKali Icon Theme Provider
# Handles user-level installation and verification of WhiteSur Icon themes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/common.sh"

ICON_DIR="$HOME/.local/share/icons"
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"
UPSTREAM_REPO="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
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
      echo "macKali Icon Theme Provider"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --check       Check if WhiteSur icon themes are installed"
      echo "  --install     Install WhiteSur icon themes to ~/.local/share/icons"
      echo "  --uninstall   Remove installed WhiteSur icon themes"
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
  for icons in WhiteSur WhiteSur-dark; do
    if [ -d "$ICON_DIR/$icons" ] || [ -d "/usr/share/icons/$icons" ]; then
      log_success "Found icon pack: $icons"
      found=true
    fi
  done
  if [ "$found" = false ]; then
    log_info "No WhiteSur icon packs currently installed."
    return 1
  fi
  return 0
}

case "$ACTION" in
  check)
    log_step "Checking for installed WhiteSur icon packs..."
    check_installed || true
    ;;

  install)
    log_step "Installing WhiteSur Icon theme..."
    if [ "$DRY_RUN" = true ]; then
      log_info "[DRY-RUN] Would clone $UPSTREAM_REPO (depth 1) into temporary build directory."
      log_info "[DRY-RUN] Would execute upstream user-level installer to ~/.local/share/icons."
      log_info "[DRY-RUN] Would track installed icon directories in $MANIFEST_FILE."
      exit 0
    fi

    if ! has_cmd git; then
      log_error "git is required to fetch WhiteSur icon theme repository."
      exit 1
    fi

    TMP_DIR="$(mktemp -d /tmp/whitesur-icons-XXXXXX)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    log_info "Cloning WhiteSur icon theme repository (shallow clone)..."
    git clone --depth 1 "$UPSTREAM_REPO" "$TMP_DIR/repo"

    log_info "Running user-level icon installer (dest: $ICON_DIR)..."
    mkdir -p "$ICON_DIR"
    (
      cd "$TMP_DIR/repo"
      ./install.sh -d "$ICON_DIR"
    )

    for icons in WhiteSur WhiteSur-dark; do
      if [ -d "$ICON_DIR/$icons" ]; then
        track_installed_dir "$ICON_DIR/$icons"
      fi
    done

    log_success "WhiteSur Icon theme installed to $ICON_DIR"
    ;;

  uninstall)
    log_step "Removing WhiteSur Icon theme..."
    for icons in WhiteSur WhiteSur-dark; do
      if [ -d "$ICON_DIR/$icons" ]; then
        if [ "$DRY_RUN" = true ]; then
          log_info "[DRY-RUN] Would delete: $ICON_DIR/$icons"
        else
          rm -rf "$ICON_DIR/$icons"
          log_success "Removed: $ICON_DIR/$icons"
        fi
      fi
    done
    ;;
esac
