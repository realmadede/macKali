#!/usr/bin/env bash
# macKali Uninstallation & System Restoration Utility
# Completely removes macKali assets and restores Kali Linux desktop settings

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

RESTORE_BACKUP=false
RESET_DEFAULTS=false
PURGE_ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-backup|-r)
      RESTORE_BACKUP=true
      shift
      ;;
    --reset-defaults|-d)
      RESET_DEFAULTS=true
      shift
      ;;
    --purge|-p)
      PURGE_ALL=true
      RESET_DEFAULTS=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Completely remove macKali assets and restore Kali Linux defaults."
      echo ""
      echo "Options:"
      echo "  -r, --restore-backup   Restore settings from the latest macKali backup"
      echo "  -d, --reset-defaults   Reset all modified GNOME settings back to Kali Linux system defaults"
      echo "  -p, --purge            Remove all assets, reset GNOME settings to default, and delete backups"
      echo "  -h, --help             Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 --restore-backup    # Remove cursors and restore your previous settings"
      echo "  $0 --reset-defaults    # Remove cursors and reset GNOME to original Kali defaults"
      echo "  $0 --purge             # Complete nuclear cleanup (zero trace left)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

echo "============================================================"
echo "          macKali Complete Uninstallation & Cleanup         "
echo "============================================================"
log_step "Starting removal process..."

# 1. Remove user cursor theme
USER_ICON_DIR="$HOME/.local/share/icons/WhiteSur-cursors"
if [ -d "$USER_ICON_DIR" ]; then
  log_info "Removing user cursor theme: $USER_ICON_DIR"
  rm -rf "$USER_ICON_DIR"
  log_success "User cursor directory deleted."
else
  log_info "No user cursor directory found at $USER_ICON_DIR"
fi

# 2. Remove system-wide cursor theme (if installed with root)
SYS_ICON_DIR="/usr/share/icons/WhiteSur-cursors"
if [ -d "$SYS_ICON_DIR" ]; then
  if [ "$EUID" -eq 0 ]; then
    log_info "Removing system-wide cursor theme: $SYS_ICON_DIR"
    rm -rf "$SYS_ICON_DIR"
    log_success "System cursor directory deleted."
  else
    log_warn "System-wide cursors detected at $SYS_ICON_DIR."
    log_warn "To remove them, run: sudo $0"
  fi
fi

# 2.5 Remove macKali wallpapers and tracked provider assets
WALLPAPER_DIR="$HOME/.local/share/backgrounds/macKali"
if [ -d "$WALLPAPER_DIR" ]; then
  log_info "Removing macKali wallpapers: $WALLPAPER_DIR"
  rm -rf "$WALLPAPER_DIR"
  log_success "macKali wallpapers removed."
fi

# Remove tracked installed files from file-manifest.json
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"
if [ -f "$MANIFEST_FILE" ] && has_cmd jq; then
  log_info "Cleaning up tracked files recorded in $MANIFEST_FILE..."
  mapfile -t TRACKED < <(jq -r '.[]' "$MANIFEST_FILE" 2>/dev/null || true)
  for item in "${TRACKED[@]}"; do
    if [ -e "$item" ]; then
      log_info "Removing tracked item: $item"
      rm -rf "$item"
    fi
  done
  log_success "Tracked macKali files removed."
fi

# 3. Settings Restoration: Backup vs System Defaults
if [ "$RESTORE_BACKUP" = true ]; then
  log_step "Restoring GNOME settings from latest backup..."
  if [ -f "$REPO_ROOT/scripts/restore.sh" ]; then
    "$REPO_ROOT/scripts/restore.sh"
  fi
elif [ "$RESET_DEFAULTS" = true ]; then
  log_step "Resetting GNOME settings to Kali Linux system defaults..."

  if has_cmd gsettings; then
    log_info "Resetting cursor-theme to default..."
    gsettings reset org.gnome.desktop.interface cursor-theme 2>/dev/null || true

    log_info "Resetting cursor-size to default..."
    gsettings reset org.gnome.desktop.interface cursor-size 2>/dev/null || true

    log_info "Resetting window button-layout to default..."
    gsettings reset org.gnome.desktop.wm.preferences button-layout 2>/dev/null || true

    log_info "Resetting interface font and theme settings..."
    gsettings reset org.gnome.desktop.interface icon-theme 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface gtk-theme 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface color-scheme 2>/dev/null || true

    log_info "Resetting desktop background wallpapers..."
    gsettings reset org.gnome.desktop.background picture-uri 2>/dev/null || true
    gsettings reset org.gnome.desktop.background picture-uri-dark 2>/dev/null || true

    if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
      log_info "Resetting user-theme shell name..."
      gsettings reset org.gnome.shell.extensions.user-theme name 2>/dev/null || true
    fi
  fi

  # Safely reconcile extensions and dock settings
  if [ -x "$REPO_ROOT/scripts/extensions-manager.sh" ]; then
    log_info "Reverting macKali extension modifications via extensions-manager.sh..."
    "$REPO_ROOT/scripts/extensions-manager.sh" --restore || true
  elif has_cmd dconf; then
    log_info "Reverting macKali extension configurations in dconf..."
    local dock_backup="$HOME/.config/macKali/extensions/backups/dash-to-dock-pre-mackali.dconf"
    if [ -f "$dock_backup" ] && [ -s "$dock_backup" ]; then
      dconf reset -f /org/gnome/shell/extensions/dash-to-dock/ 2>/dev/null || true
      dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$dock_backup" 2>/dev/null || true
    fi
    dconf reset -f /org/gnome/shell/extensions/blur-my-shell/ 2>/dev/null || true
    dconf reset -f /org/gnome/shell/extensions/desktop-cube/ 2>/dev/null || true
    dconf reset -f /org/gnome/shell/extensions/com/github/hermes83/ 2>/dev/null || true
  fi

  log_success "All desktop settings reverted to standard Kali Linux defaults."
fi

# 4. Purge backup cache if requested
if [ "$PURGE_ALL" = true ]; then
  BACKUP_DIR="$HOME/.config/macKali"
  if [ -d "$BACKUP_DIR" ]; then
    log_info "Purging macKali cache and backups ($BACKUP_DIR)..."
    rm -rf "$BACKUP_DIR"
    log_success "macKali cache and backups purged."
  fi
fi

echo ""
echo "============================================================"
log_success "Uninstallation complete. Your system is restored."
echo "============================================================"
