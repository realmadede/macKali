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
    dconf load /org/gnome/desktop/ < "$SOURCE_DIR/org_gnome_desktop.dconf" 2>/dev/null || true
    log_success "Restored /org/gnome/desktop/"
  fi

  if [ -f "$SOURCE_DIR/org_gnome_shell.dconf" ]; then
    log_info "Restoring /org/gnome/shell/ settings..."
    dconf load /org/gnome/shell/ < "$SOURCE_DIR/org_gnome_shell.dconf" 2>/dev/null || true
    log_success "Restored /org/gnome/shell/"
  fi

  if [ -f "$SOURCE_DIR/org_gnome_shell_extensions.dconf" ]; then
    log_info "Restoring /org/gnome/shell/extensions/ settings..."
    dconf load /org/gnome/shell/extensions/ < "$SOURCE_DIR/org_gnome_shell_extensions.dconf" 2>/dev/null || true
    log_success "Restored /org/gnome/shell/extensions/"
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

# 3. Restore extension enabled states
if [ -f "$SOURCE_DIR/enabled_extensions.txt" ] && has_cmd gnome-extensions; then
  log_info "Reconciling enabled GNOME Shell extensions..."
  mapfile -t BACKUP_ENABLED < "$SOURCE_DIR/enabled_extensions.txt"
  mapfile -t CURRENT_ENABLED < <(gnome-extensions list --enabled 2>/dev/null || true)

  # Check macKali target extensions specifically
  TARGET_EXTS=(
    "dash-to-dock@micxgx.gmail.com"
    "blur-my-shell@aunetx"
    "compiz-alike-magic-lamp-effect@hermes83.github.com"
    "compiz-windows-effect@hermes83.github.com"
    "desktop-cube@schneegans.github.com"
  )

  for uuid in "${TARGET_EXTS[@]}"; do
    should_enable=false
    for item in "${BACKUP_ENABLED[@]}"; do
      [ "$item" = "$uuid" ] && should_enable=true
    done

    is_enabled=false
    for cur in "${CURRENT_ENABLED[@]}"; do
      [ "$cur" = "$uuid" ] && is_enabled=true
    done

    if [ "$should_enable" = true ] && [ "$is_enabled" = false ]; then
      log_info "Re-enabling extension: $uuid"
      gnome-extensions enable "$uuid" 2>/dev/null || true
    elif [ "$should_enable" = false ] && [ "$is_enabled" = true ]; then
      log_info "Disabling extension: $uuid"
      gnome-extensions disable "$uuid" 2>/dev/null || true
    fi
  done
fi

# 4. Restore extensions-state.json if available
if [ -f "$SOURCE_DIR/extensions-state.json" ]; then
  mkdir -p "$HOME/.config/macKali"
  cp "$SOURCE_DIR/extensions-state.json" "$HOME/.config/macKali/extensions-state.json"
fi

log_success "Restoration completed successfully."
