#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

BACKUP_BASE_DIR="$HOME/.config/macKali/backups"
SOURCE_DIR=""

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from|-f)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --list|-l)
      echo "Available backups in $BACKUP_BASE_DIR:"
      if [ -d "$BACKUP_BASE_DIR" ]; then
        ls -1 "$BACKUP_BASE_DIR"
      else
        echo "  No backups found."
      fi
      exit 0
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Restore GNOME desktop settings from a macKali backup."
      echo ""
      echo "Options:"
      echo "  -f, --from PATH   Path to specific backup directory (default: latest)"
      echo "  -l, --list        List available backups"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

# If no directory specified, find the most recent backup
if [ -z "$SOURCE_DIR" ]; then
  if [ ! -d "$BACKUP_BASE_DIR" ]; then
    log_error "No backup directory found at $BACKUP_BASE_DIR"
    exit 1
  fi

  LATEST_BACKUP="$(ls -td "$BACKUP_BASE_DIR"/* 2>/dev/null | head -n 1 || true)"
  if [ -z "$LATEST_BACKUP" ] || [ ! -d "$LATEST_BACKUP" ]; then
    log_error "No previous backups found in $BACKUP_BASE_DIR"
    exit 1
  fi
  SOURCE_DIR="$LATEST_BACKUP"
fi

if [ ! -d "$SOURCE_DIR" ]; then
  log_error "Specified backup directory does not exist: $SOURCE_DIR"
  exit 1
fi

log_step "Restoring configuration from: $SOURCE_DIR"

# 1. Restore dconf settings
if has_cmd dconf; then
  if [ -f "$SOURCE_DIR/org_gnome_desktop.dconf" ]; then
    log_info "Restoring /org/gnome/desktop/ settings..."
    dconf load /org/gnome/desktop/ < "$SOURCE_DIR/org_gnome_desktop.dconf"
    log_success "Restored /org/gnome/desktop/"
  fi

  if [ -f "$SOURCE_DIR/org_gnome_shell.dconf" ]; then
    log_info "Restoring /org/gnome/shell/ settings..."
    dconf load /org/gnome/shell/ < "$SOURCE_DIR/org_gnome_shell.dconf"
    log_success "Restored /org/gnome/shell/"
  fi
else
  log_warn "dconf command not available; cannot restore dconf keys."
fi

# 2. Restore interface values from backup-meta.json
if [ -f "$SOURCE_DIR/backup-meta.json" ] && has_cmd jq && has_cmd gsettings; then
  CURSOR_VAL="$(jq -r '.cursor_theme // empty' "$SOURCE_DIR/backup-meta.json")"
  ICON_VAL="$(jq -r '.icon_theme // empty' "$SOURCE_DIR/backup-meta.json")"
  GTK_VAL="$(jq -r '.gtk_theme // empty' "$SOURCE_DIR/backup-meta.json")"

  if [ -n "$CURSOR_VAL" ] && [ "$CURSOR_VAL" != "null" ]; then
    log_info "Restoring cursor theme: $CURSOR_VAL"
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_VAL" || true
  fi

  if [ -n "$ICON_VAL" ] && [ "$ICON_VAL" != "null" ]; then
    log_info "Restoring icon theme: $ICON_VAL"
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_VAL" || true
  fi

  if [ -n "$GTK_VAL" ] && [ "$GTK_VAL" != "null" ]; then
    log_info "Restoring GTK theme: $GTK_VAL"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_VAL" || true
  fi

  COLOR_VAL="$(jq -r '.color_scheme // empty' "$SOURCE_DIR/backup-meta.json")"
  if [ -n "$COLOR_VAL" ] && [ "$COLOR_VAL" != "null" ]; then
    log_info "Restoring color-scheme: $COLOR_VAL"
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_VAL" || true
  fi

  BUTTONS_VAL="$(jq -r '.button_layout // empty' "$SOURCE_DIR/backup-meta.json")"
  if [ -n "$BUTTONS_VAL" ] && [ "$BUTTONS_VAL" != "null" ]; then
    log_info "Restoring window button-layout: $BUTTONS_VAL"
    gsettings set org.gnome.desktop.wm.preferences button-layout "$BUTTONS_VAL" || true
  fi

  LIGHT_WP="$(jq -r '.picture_uri // empty' "$SOURCE_DIR/backup-meta.json")"
  if [ -n "$LIGHT_WP" ] && [ "$LIGHT_WP" != "null" ]; then
    log_info "Restoring light wallpaper: $LIGHT_WP"
    gsettings set org.gnome.desktop.background picture-uri "$LIGHT_WP" || true
  fi

  DARK_WP="$(jq -r '.picture_uri_dark // empty' "$SOURCE_DIR/backup-meta.json")"
  if [ -n "$DARK_WP" ] && [ "$DARK_WP" != "null" ]; then
    log_info "Restoring dark wallpaper: $DARK_WP"
    gsettings set org.gnome.desktop.background picture-uri-dark "$DARK_WP" || true
  fi

  SHELL_VAL="$(jq -r '.shell_theme // empty' "$SOURCE_DIR/backup-meta.json")"
  if [ -n "$SHELL_VAL" ] && [ "$SHELL_VAL" != "null" ] && [ "$SHELL_VAL" != "default" ] && gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    log_info "Restoring user-theme shell name: $SHELL_VAL"
    gsettings set org.gnome.shell.extensions.user-theme name "$SHELL_VAL" || true
  fi
fi

log_success "Restoration completed successfully."
