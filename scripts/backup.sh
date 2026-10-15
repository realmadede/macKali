#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

BACKUP_BASE_DIR="$HOME/.config/macKali/backups"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
TARGET_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"

# Parse custom destination if provided
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest|-d)
      TARGET_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Create a safe timestamped backup of current GNOME desktop settings."
      echo ""
      echo "Options:"
      echo "  -d, --dest PATH   Custom backup directory location"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

log_step "Creating macKali GNOME configuration backup..."
mkdir -p "$TARGET_DIR"

detect_os
detect_gnome_version

# 1. Backup dconf settings
if has_cmd dconf; then
  log_info "Backing up /org/gnome/desktop/..."
  dconf dump /org/gnome/desktop/ > "$TARGET_DIR/org_gnome_desktop.dconf" 2>/dev/null || true

  log_info "Backing up /org/gnome/shell/..."
  dconf dump /org/gnome/shell/ > "$TARGET_DIR/org_gnome_shell.dconf" 2>/dev/null || true
else
  log_warn "dconf command not found; skipping dconf database dumps."
fi

# 2. Backup GSettings interface values
CURRENT_CURSOR=""
CURRENT_ICON=""
CURRENT_GTK=""

if has_cmd gsettings; then
  CURRENT_CURSOR="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'" || echo "default")"
  CURRENT_ICON="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo "default")"
  CURRENT_GTK="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo "default")"
fi

# 3. Backup enabled extensions list
ENABLED_EXTENSIONS=()
if has_cmd gnome-extensions; then
  mapfile -t ENABLED_EXTENSIONS < <(gnome-extensions list --enabled 2>/dev/null || true)
fi

# 4. Write manifest
cat <<EOF > "$TARGET_DIR/backup-meta.json"
{
  "timestamp": "$TIMESTAMP",
  "user": "$USER",
  "hostname": "$(hostname)",
  "os": "$OS_NAME",
  "gnome_version": "$GNOME_VERSION",
  "cursor_theme": "$CURRENT_CURSOR",
  "icon_theme": "$CURRENT_ICON",
  "gtk_theme": "$CURRENT_GTK",
  "files": [
    "org_gnome_desktop.dconf",
    "org_gnome_shell.dconf"
  ]
}
EOF

# Save enabled extensions list as plain text
printf "%s\n" "${ENABLED_EXTENSIONS[@]}" > "$TARGET_DIR/enabled_extensions.txt"

log_success "Backup completed successfully!"
echo "  Location: $TARGET_DIR"
echo "  To restore this backup at any time, run:"
echo "    $REPO_ROOT/scripts/restore.sh --from $TARGET_DIR"
