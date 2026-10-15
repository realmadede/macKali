#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

RESTORE_SETTINGS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-settings)
      RESTORE_SETTINGS=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Safely remove installed macKali assets and optionally revert settings."
      echo ""
      echo "Options:"
      echo "      --restore-settings   Revert GNOME settings to the latest available backup"
      echo "  -h, --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

log_step "Uninstalling macKali components..."

# 1. Remove user cursor theme
USER_ICON_DIR="$HOME/.local/share/icons/WhiteSur-cursors"
if [ -d "$USER_ICON_DIR" ]; then
  log_info "Removing user cursor theme: $USER_ICON_DIR"
  rm -rf "$USER_ICON_DIR"
  log_success "User cursor theme removed."
else
  log_info "No user cursor theme found at $USER_ICON_DIR"
fi

# 2. Check system cursor theme
SYS_ICON_DIR="/usr/share/icons/WhiteSur-cursors"
if [ -d "$SYS_ICON_DIR" ]; then
  if [ "$EUID" -eq 0 ]; then
    log_info "Removing system cursor theme: $SYS_ICON_DIR"
    rm -rf "$SYS_ICON_DIR"
    log_success "System cursor theme removed."
  else
    log_warn "System cursor theme detected at $SYS_ICON_DIR."
    log_warn "Run 'sudo $0' to remove system-wide assets."
  fi
fi

# 3. Restore settings if requested
if [ "$RESTORE_SETTINGS" = true ]; then
  log_step "Restoring GNOME settings from latest backup..."
  "$REPO_ROOT/scripts/restore.sh"
fi

log_success "Uninstallation tasks completed."
