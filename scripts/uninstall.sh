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
SCOPED_REVERT=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-backup|-r)
      RESTORE_BACKUP=true
      SCOPED_REVERT=false
      shift
      ;;
    --reset-defaults|--restore-settings|-d)
      RESET_DEFAULTS=true
      SCOPED_REVERT=false
      shift
      ;;
    --purge|-p)
      PURGE_ALL=true
      RESET_DEFAULTS=true
      SCOPED_REVERT=false
      shift
      ;;
    --yes|-y)
      # Non-interactive confirmation
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Completely remove macKali assets and restore desktop settings."
      echo ""
      echo "Options:"
      echo "  (default)              Safely reverse only macKali-managed files and settings"
      echo "  -r, --restore-backup   Restore full desktop snapshot from the latest macKali backup"
      echo "  -d, --reset-defaults   Reset all modified GNOME settings back to Kali Linux system defaults"
      echo "  -p, --purge            Remove all assets, reset GNOME settings to default, and delete backups"
      echo "  -y, --yes              Skip interactive confirmation prompts"
      echo "  -h, --help             Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                     # Scoped reversal of macKali-managed changes (preserves unrelated settings)"
      echo "  $0 --restore-backup    # Restore full desktop snapshot from your latest backup"
      echo "  $0 --reset-defaults    # Remove assets and reset GNOME to original Kali defaults"
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

if [ -L "$HOME/.icons/WhiteSur-cursors" ] || [ -d "$HOME/.icons/WhiteSur-cursors" ]; then
  rm -rf "$HOME/.icons/WhiteSur-cursors"
fi
if [ -f "$HOME/.icons/default/index.theme" ]; then
  if grep -q "Inherits=WhiteSur-cursors" "$HOME/.icons/default/index.theme" 2>/dev/null; then
    rm -f "$HOME/.icons/default/index.theme"
  fi
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

# 2.4 Safely uninstall Qt/Kvantum provider if state or files are present
if [ -x "$REPO_ROOT/scripts/providers/qt-provider.sh" ]; then
  if [ -f "$HOME/.config/macKali/qt-state.json" ] || [ -f "$HOME/.config/environment.d/10-mackali-qt.conf" ] || [ -d "$HOME/.config/Kvantum/WhiteSurDark" ] || [ -d "$HOME/.config/Kvantum/WhiteSur" ]; then
    "$REPO_ROOT/scripts/providers/qt-provider.sh" --uninstall || true
  fi
fi

# 2.5 Remove macKali wallpapers and tracked provider assets
WALLPAPER_DIR="$HOME/.local/share/backgrounds/macKali"
if [ -d "$WALLPAPER_DIR" ]; then
  log_info "Removing macKali wallpapers: $WALLPAPER_DIR"
  rm -rf "$WALLPAPER_DIR"
  log_success "macKali wallpapers removed."
fi

STATE_DIR="$HOME/.config/macKali"
MANIFEST_FILE="$STATE_DIR/file-manifest.json"

# 2.6 If performing scoped reversal, revert appearance and traffic lights first while snapshots and backups are intact
if [ "$SCOPED_REVERT" = true ]; then
  log_step "Performing scoped reversal of macKali-managed desktop settings..."
  if [ -x "$REPO_ROOT/scripts/appearance.sh" ]; then
    if [ -f "$STATE_DIR/appearance_snapshot.json" ]; then
      "$REPO_ROOT/scripts/appearance.sh" --revert || true
    elif [ -f "$STATE_DIR/traffic_lights_snapshot.json" ]; then
      "$REPO_ROOT/scripts/appearance.sh" --revert-traffic-lights || true
    fi
  fi

  if [ -x "$REPO_ROOT/scripts/extensions-manager.sh" ] && [ -f "$STATE_DIR/extensions-state.json" ]; then
    "$REPO_ROOT/scripts/extensions-manager.sh" --restore || true
  fi
fi

# Remove tracked installed files from file-manifest.json
if [ -f "$MANIFEST_FILE" ] && has_cmd jq; then
  log_info "Cleaning up tracked files recorded in $MANIFEST_FILE..."
  mapfile -t TRACKED < <(jq -r '.[]' "$MANIFEST_FILE" 2>/dev/null || true)
  for item in "${TRACKED[@]}"; do
    if [ -e "$item" ]; then
      if [[ "$item" == */gtk-4.0/gtk.css || "$item" == */gtk-3.0/gtk.css ]]; then
        if grep -qF "/* === BEGIN MACKALI TRAFFIC LIGHTS === */" "$item" 2>/dev/null; then
          log_info "Reverting macKali traffic lights styling from $item..."
          python3 -c "
with open('$item', 'r') as f: content = f.read()
import re
new_c = re.sub(r'\n?/\* === BEGIN MACKALI TRAFFIC LIGHTS === \*/.*?/\* === END MACKALI TRAFFIC LIGHTS === \*/\n?', '', content, flags=re.DOTALL)
if new_c.strip():
    with open('$item', 'w') as f: f.write(new_c.strip() + '\n')
else:
    import os; os.remove('$item')
" 2>/dev/null || rm -f "$item"
        fi
      elif [[ "$item" == */gtk-4.0/settings.ini || "$item" == */gtk-3.0/settings.ini ]]; then
        log_info "Reverting macKali settings configuration from $item..."
        bak_ini="$STATE_DIR/backups/$(basename "$(dirname "$item")")-settings.ini.bak"
        if [ -f "$bak_ini" ]; then
          cp -p "$bak_ini" "$item"
          rm -f "$bak_ini"
        elif [ "$SCOPED_REVERT" != true ]; then
          python3 -c "
import configparser, os
p = '$item'
config = configparser.ConfigParser()
config.read(p)
if config.has_section('Settings'):
    for k in ('gtk-decoration-layout', 'gtk-theme-name', 'gtk-cursor-theme-name', 'gtk-cursor-theme-size'):
        if config.has_option('Settings', k):
            config.remove_option('Settings', k)
    if not config.options('Settings'):
        config.remove_section('Settings')
if not config.sections():
    os.remove(p)
else:
    with open(p, 'w') as f:
        config.write(f, space_around_delimiters=False)
" 2>/dev/null || rm -f "$item"
        fi
      else
        log_info "Removing tracked item: $item"
        rm -rf "$item"
      fi
    fi
  done
  rm -f "$MANIFEST_FILE"
  log_success "Tracked macKali files removed."
fi

# 3. Settings Restoration: Full Snapshot Restore vs System Defaults
if [ "$RESTORE_BACKUP" = true ]; then
  log_step "Restoring full GNOME desktop snapshot from latest backup..."
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
    gsettings reset org.gnome.desktop.wm.preferences theme 2>/dev/null || true

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
    dock_backup="$HOME/.config/macKali/backups/dash-to-dock-pre-mackali.dconf"
    if [ -f "$dock_backup" ] && [ -s "$dock_backup" ]; then
      dconf reset -f /org/gnome/shell/extensions/dash-to-dock/ 2>/dev/null || true
      dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$dock_backup" 2>/dev/null || true
    fi
    dconf reset -f /org/gnome/shell/extensions/blur-my-shell/ 2>/dev/null || true
    dconf reset -f /org/gnome/shell/extensions/desktop-cube/ 2>/dev/null || true
    dconf reset -f /org/gnome/shell/extensions/com/github/hermes83/ 2>/dev/null || true
  fi

  log_success "All desktop settings reverted to standard Kali Linux defaults."
elif [ "$SCOPED_REVERT" = true ]; then
  log_success "Scoped macKali settings reversed while preserving unrelated user configurations."
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
