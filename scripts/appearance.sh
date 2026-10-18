#!/usr/bin/env bash
# macKali Appearance Manager (Phase 2)
# Manages GTK, Shell, Icons, Cursors, Wallpapers, Window Controls, and Light/Dark modes
# Supports per-setting backups, dry-run previews, explicit confirmation, and reversible rollback.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

SNAPSHOT_FILE="$HOME/.config/macKali/appearance_snapshot.json"
TRAFFIC_SNAPSHOT_FILE="$HOME/.config/macKali/traffic_lights_snapshot.json"
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"
STATE_DIR="$HOME/.config/macKali"
GTK4_CSS="$HOME/.config/gtk-4.0/gtk.css"
GTK3_CSS="$HOME/.config/gtk-3.0/gtk.css"
GTK4_SETTINGS="$HOME/.config/gtk-4.0/settings.ini"
GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
GTK4_TEMPLATE="$REPO_ROOT/config/gnome/traffic-lights-gtk4.css"
GTK3_TEMPLATE="$REPO_ROOT/config/gnome/traffic-lights-gtk3.css"

DRY_RUN=false
CONFIRM=true
ACTION="apply" # apply, revert, revert_traffic_lights, reset_defaults, status

# Requested appearance changes
REQ_COLOR_SCHEME=""
REQ_BUTTON_LAYOUT=""
REQ_GTK_THEME=""
REQ_SHELL_THEME=""
REQ_ICON_THEME=""
REQ_CURSOR_THEME=""
REQ_WALLPAPER_MODE="" # bundled, file, url
REQ_WALLPAPER_ARG=""
REQ_TRAFFIC_LIGHTS=false

print_usage() {
  echo "macKali Appearance Manager"
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Appearance Configuration Options:"
  echo "  --mode [dark|light|auto]      Set GNOME color-scheme ('prefer-dark', 'prefer-light', 'default')"
  echo "  --buttons [left|right]        Set window button layout (left: traffic lights, right: Kali default)"
  echo "  --traffic-lights              Apply authentic macOS traffic lights (GTK3, GTK4 & Libadwaita)"
  echo "  --revert-traffic-lights       Revert only traffic light styling without affecting desktop"
  echo "  --theme NAME                  Set GTK theme (e.g. WhiteSur-Dark, WhiteSur-Light)"
  echo "  --shell-theme NAME            Set GNOME Shell theme (requires User Theme extension)"
  echo "  --icons NAME                  Set icon theme (e.g. WhiteSur-dark, WhiteSur)"
  echo "  --cursor NAME                 Set cursor theme (e.g. WhiteSur-cursors)"
  echo "  --wallpaper-bundled           Apply bundled 4K macOS Light & Dark wallpapers"
  echo "  --wallpaper-file PATH         Apply custom local wallpaper"
  echo "  --preset [macos-dark|macos-light] Apply full macOS appearance preset"
  echo ""
  echo "Safety & Rollback Options:"
  echo "  --status                      Display current appearance configuration"
  echo "  --preview, --dry-run          Preview proposed changes without modifying system"
  echo "  -y, --yes                     Skip confirmation prompt"
  echo "  --revert                      Restore previous appearance settings from snapshot"
  echo "  --reset-defaults              Reset appearance settings to Kali Linux system defaults"
  echo "  -h, --help                    Show this help message"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      case "$2" in
        dark) REQ_COLOR_SCHEME="prefer-dark" ;;
        light) REQ_COLOR_SCHEME="prefer-light" ;;
        auto|default) REQ_COLOR_SCHEME="default" ;;
        *) log_error "Invalid mode: $2 (choose dark, light, or auto)"; exit 1 ;;
      esac
      shift 2
      ;;
    --buttons)
      case "$2" in
        left|mac|macos)
          REQ_BUTTON_LAYOUT="close,minimize,maximize:"
          REQ_TRAFFIC_LIGHTS=true
          ;;
        right|kali|default)
          REQ_BUTTON_LAYOUT="appmenu:minimize,maximize,close"
          ;;
        *) log_error "Invalid button layout: $2 (choose left or right)"; exit 1 ;;
      esac
      shift 2
      ;;
    --traffic-lights)
      REQ_TRAFFIC_LIGHTS=true
      REQ_BUTTON_LAYOUT="close,minimize,maximize:"
      shift
      ;;
    --revert-traffic-lights)
      ACTION="revert_traffic_lights"
      shift
      ;;
    --theme)
      REQ_GTK_THEME="$2"
      shift 2
      ;;
    --shell-theme)
      REQ_SHELL_THEME="$2"
      shift 2
      ;;
    --icons)
      REQ_ICON_THEME="$2"
      shift 2
      ;;
    --cursor)
      REQ_CURSOR_THEME="$2"
      shift 2
      ;;
    --wallpaper-bundled)
      REQ_WALLPAPER_MODE="bundled"
      shift
      ;;
    --wallpaper-file)
      REQ_WALLPAPER_MODE="file"
      REQ_WALLPAPER_ARG="$2"
      shift 2
      ;;
    --preset)
      case "$2" in
        macos-dark)
          REQ_COLOR_SCHEME="prefer-dark"
          REQ_BUTTON_LAYOUT="close,minimize,maximize:"
          REQ_GTK_THEME="WhiteSur-Dark"
          REQ_SHELL_THEME="WhiteSur-Dark"
          REQ_ICON_THEME="WhiteSur-dark"
          REQ_CURSOR_THEME="WhiteSur-cursors"
          REQ_WALLPAPER_MODE="bundled"
          REQ_TRAFFIC_LIGHTS=true
          ;;
        macos-light)
          REQ_COLOR_SCHEME="prefer-light"
          REQ_BUTTON_LAYOUT="close,minimize,maximize:"
          REQ_GTK_THEME="WhiteSur-Light"
          REQ_SHELL_THEME="WhiteSur-Light"
          REQ_ICON_THEME="WhiteSur"
          REQ_CURSOR_THEME="WhiteSur-cursors"
          REQ_WALLPAPER_MODE="bundled"
          REQ_TRAFFIC_LIGHTS=true
          ;;
        *)
          log_error "Unknown preset: $2 (choose macos-dark or macos-light)"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --preview|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -y|--yes)
      CONFIRM=false
      shift
      ;;
    --status)
      ACTION="status"
      shift
      ;;
    --revert)
      if [ "$REQ_TRAFFIC_LIGHTS" = true ]; then
        ACTION="revert_traffic_lights"
      else
        ACTION="revert"
      fi
      shift
      ;;
    --reset-defaults)
      ACTION="reset_defaults"
      shift
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

# Track installed file in manifest
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

# Apply narrowly scoped CSS block to target file
apply_traffic_lights_css() {
  local target_file="$1"
  local template_file="$2"
  local backup_dest="$3"

  local start_marker="/* === BEGIN MACKALI TRAFFIC LIGHTS === */"
  local end_marker="/* === END MACKALI TRAFFIC LIGHTS === */"

  mkdir -p "$(dirname "$target_file")"
  mkdir -p "$(dirname "$backup_dest")"

  if [ -f "$target_file" ]; then
    if [ ! -f "$backup_dest" ]; then
      cp -p "$target_file" "$backup_dest"
    fi
    if grep -qF "$start_marker" "$target_file"; then
      python3 -c "
with open('$target_file', 'r') as f: content = f.read()
with open('$template_file', 'r') as f: snippet = f.read().strip()
block = f'$start_marker\n{snippet}\n$end_marker'
import re
new_content = re.sub(r'/\* === BEGIN MACKALI TRAFFIC LIGHTS === \*/.*?/\* === END MACKALI TRAFFIC LIGHTS === \*/', block, content, flags=re.DOTALL)
with open('$target_file', 'w') as f: f.write(new_content)
"
    else
      echo "" >> "$target_file"
      echo "$start_marker" >> "$target_file"
      cat "$template_file" >> "$target_file"
      echo "$end_marker" >> "$target_file"
    fi
  else
    echo "$start_marker" > "$target_file"
    cat "$template_file" >> "$target_file"
    echo "$end_marker" >> "$target_file"
  fi

  track_installed_file "$target_file"
}

# Revert scoped CSS block from target file
revert_traffic_lights_css() {
  local target_file="$1"
  local was_created="${2:-false}"
  local backup_dest="${3:-}"

  local start_marker="/* === BEGIN MACKALI TRAFFIC LIGHTS === */"
  local end_marker="/* === END MACKALI TRAFFIC LIGHTS === */"

  if [ ! -f "$target_file" ]; then
    return 0
  fi

  if grep -qF "$start_marker" "$target_file"; then
    python3 -c "
with open('$target_file', 'r') as f: content = f.read()
import re
new_c = re.sub(r'\n?/\* === BEGIN MACKALI TRAFFIC LIGHTS === \*/.*?/\* === END MACKALI TRAFFIC LIGHTS === \*/\n?', '', content, flags=re.DOTALL)
if new_c.strip():
    with open('$target_file', 'w') as f: f.write(new_c.strip() + '\n')
else:
    import os; os.remove('$target_file')
" 2>/dev/null || true
    log_info "Removed macKali traffic lights block from $target_file"
  elif [ "$was_created" = "true" ]; then
    rm -f "$target_file"
    log_info "Removed macKali-created stylesheet: $target_file"
  elif [ -n "$backup_dest" ] && [ -f "$backup_dest" ]; then
    cp -p "$backup_dest" "$target_file"
    log_info "Restored stylesheet from backup: $target_file"
  fi
}

# Apply decoration layout and GTK theme to settings.ini safely
apply_settings_ini() {
  local target_file="$1"
  local theme_name="$2"
  local backup_dest="$3"
  local force_theme="${4:-false}"

  mkdir -p "$(dirname "$target_file")"
  mkdir -p "$(dirname "$backup_dest")"

  if [ -f "$target_file" ]; then
    if [ ! -f "$backup_dest" ]; then
      cp -p "$target_file" "$backup_dest"
    fi
    python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('$target_file')
if not config.has_section('Settings'):
    config.add_section('Settings')
config.set('Settings', 'gtk-decoration-layout', 'close,minimize,maximize:')
if '$theme_name' and ('$force_theme' == 'true' or not config.has_option('Settings', 'gtk-theme-name')):
    config.set('Settings', 'gtk-theme-name', '$theme_name')
with open('$target_file', 'w') as f:
    config.write(f, space_around_delimiters=False)
" 2>/dev/null || true
  else
    cat <<EOF > "$target_file"
[Settings]
gtk-theme-name=$theme_name
gtk-decoration-layout=close,minimize,maximize:
EOF
  fi

  track_installed_file "$target_file"
}

# Revert settings.ini modification
revert_settings_ini() {
  local target_file="$1"
  local was_created="${2:-false}"
  local backup_dest="${3:-}"

  if [ ! -f "$target_file" ]; then
    return 0
  fi

  if [ "$was_created" = "true" ]; then
    rm -f "$target_file"
    log_info "Removed macKali-created settings: $target_file"
  elif [ -n "$backup_dest" ] && [ -f "$backup_dest" ]; then
    cp -p "$backup_dest" "$target_file"
    log_info "Restored settings from backup: $target_file"
  else
    python3 -c "
import configparser, os
p = '$target_file'
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
" 2>/dev/null || true
  fi
}

# Current settings reader
read_current_settings() {
  CUR_COLOR_SCHEME="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || echo "default")"
  CUR_BUTTON_LAYOUT="$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null | tr -d "'" || echo "default")"
  CUR_WM_THEME="$(gsettings get org.gnome.desktop.wm.preferences theme 2>/dev/null | tr -d "'" || echo "default")"
  CUR_GTK_THEME="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo "default")"
  CUR_ICON_THEME="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo "default")"
  CUR_CURSOR_THEME="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'" || echo "default")"
  CUR_CURSOR_SIZE="$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo "24")"
  CUR_WALLPAPER_LIGHT="$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'" || echo "default")"
  CUR_WALLPAPER_DARK="$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null | tr -d "'" || echo "default")"
  CUR_SHELL_THEME="not_available"
  if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    CUR_SHELL_THEME="$(gsettings get org.gnome.shell.extensions.user-theme name 2>/dev/null | tr -d "'" || echo "none")"
  fi
  CUR_TRAFFIC_LIGHTS="inactive"
  if grep -qF "/* === BEGIN MACKALI TRAFFIC LIGHTS === */" "$GTK4_CSS" 2>/dev/null || grep -qF "/* === BEGIN MACKALI TRAFFIC LIGHTS === */" "$GTK3_CSS" 2>/dev/null; then
    CUR_TRAFFIC_LIGHTS="active"
  fi
  CUR_XFWM4_LAYOUT=""
  CUR_XFWM4_THEME=""
  if has_cmd xfconf-query; then
    CUR_XFWM4_LAYOUT="$(xfconf-query -c xfwm4 -p /general/button_layout 2>/dev/null || true)"
    CUR_XFWM4_THEME="$(xfconf-query -c xfwm4 -p /general/theme 2>/dev/null || true)"
  fi
}

# 1. Action: STATUS
if [ "$ACTION" = "status" ]; then
  read_current_settings
  echo "============================================================"
  echo "               macKali Current Appearance Status            "
  echo "============================================================"
  echo "  - Color Scheme:       $CUR_COLOR_SCHEME"
  echo "  - Window Buttons:     $CUR_BUTTON_LAYOUT"
  echo "  - Traffic Lights:     $CUR_TRAFFIC_LIGHTS (macOS Left Circular Controls)"
  echo "  - GTK Theme:          $CUR_GTK_THEME"
  echo "  - WM Theme:           $CUR_WM_THEME"
  echo "  - Shell Theme:        $CUR_SHELL_THEME"
  echo "  - Icon Theme:         $CUR_ICON_THEME"
  echo "  - Cursor Theme:       $CUR_CURSOR_THEME (size: $CUR_CURSOR_SIZE)"
  echo "  - Wallpaper (Light):  $CUR_WALLPAPER_LIGHT"
  echo "  - Wallpaper (Dark):   $CUR_WALLPAPER_DARK"
  echo "============================================================"
  exit 0
fi

# 1.5 Action: REVERT TRAFFIC LIGHTS
if [ "$ACTION" = "revert_traffic_lights" ]; then
  log_step "Reverting macOS traffic lights..."
  read_current_settings

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would revert window button-layout to previous or default layout."
    log_info "[DRY-RUN] Would remove macKali traffic lights styling from $GTK4_CSS and $GTK3_CSS."
    log_info "[DRY-RUN] Would restore GTK settings.ini configuration."
    exit 0
  fi

  old_buttons=""
  old_gtk=""
  old_wm=""
  old_xfwm4_layout=""
  old_xfwm4_theme=""
  gtk4_created=false
  gtk3_created=false
  gtk4_settings_created=false
  gtk3_settings_created=false
  gtk4_backup="$STATE_DIR/backups/gtk-4.0-gtk.css.bak"
  gtk3_backup="$STATE_DIR/backups/gtk-3.0-gtk.css.bak"
  gtk4_settings_backup="$STATE_DIR/backups/gtk-4.0-settings.ini.bak"
  gtk3_settings_backup="$STATE_DIR/backups/gtk-3.0-settings.ini.bak"

  if [ -f "$TRAFFIC_SNAPSHOT_FILE" ] && has_cmd jq; then
    old_buttons="$(jq -r '.previous_button_layout // empty' "$TRAFFIC_SNAPSHOT_FILE")"
    old_gtk="$(jq -r '.previous_gtk_theme // empty' "$TRAFFIC_SNAPSHOT_FILE")"
    old_wm="$(jq -r '.previous_wm_theme // empty' "$TRAFFIC_SNAPSHOT_FILE")"
    old_xfwm4_layout="$(jq -r '.previous_xfwm4_layout // empty' "$TRAFFIC_SNAPSHOT_FILE")"
    old_xfwm4_theme="$(jq -r '.previous_xfwm4_theme // empty' "$TRAFFIC_SNAPSHOT_FILE")"
    [ "$(jq -r '.gtk4_css_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk4_created=true
    [ "$(jq -r '.gtk3_css_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk3_created=true
    [ "$(jq -r '.gtk4_settings_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk4_settings_created=true
    [ "$(jq -r '.gtk3_settings_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk3_settings_created=true
  fi

  # Fallback to system default if prior state was not recorded
  [ -z "$old_buttons" ] && old_buttons="appmenu:minimize,maximize,close"

  gsettings set org.gnome.desktop.wm.preferences button-layout "$old_buttons" 2>/dev/null || true
  log_success "Restored window button-layout: $old_buttons"

  if [ -n "$old_wm" ] && [ "$old_wm" != "$CUR_WM_THEME" ]; then
    gsettings set org.gnome.desktop.wm.preferences theme "$old_wm" 2>/dev/null || true
    log_success "Restored wm theme: $old_wm"
  fi

  if [ -n "$old_gtk" ] && [ "$old_gtk" != "$CUR_GTK_THEME" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$old_gtk" 2>/dev/null || true
    log_success "Restored gtk-theme: $old_gtk"
  fi

  if has_cmd xfconf-query; then
    [ -n "$old_xfwm4_layout" ] && xfconf-query -c xfwm4 -p /general/button_layout -s "$old_xfwm4_layout" 2>/dev/null || true
    [ -n "$old_xfwm4_theme" ] && xfconf-query -c xfwm4 -p /general/theme -s "$old_xfwm4_theme" 2>/dev/null || true
  fi

  revert_traffic_lights_css "$GTK4_CSS" "$gtk4_created" "$gtk4_backup"
  revert_traffic_lights_css "$GTK3_CSS" "$gtk3_created" "$gtk3_backup"

  revert_settings_ini "$GTK4_SETTINGS" "$gtk4_settings_created" "$gtk4_settings_backup"
  revert_settings_ini "$GTK3_SETTINGS" "$gtk3_settings_created" "$gtk3_settings_backup"

  rm -f "$gtk4_backup" "$gtk3_backup" "$gtk4_settings_backup" "$gtk3_settings_backup"
  rm -f "$TRAFFIC_SNAPSHOT_FILE"
  log_success "macOS traffic lights reverted successfully."
  exit 0
fi

# 2. Action: REVERT (Full)
if [ "$ACTION" = "revert" ]; then
  log_step "Reverting appearance to last snapshot..."
  if [ ! -f "$SNAPSHOT_FILE" ]; then
    log_error "No appearance snapshot found at $SNAPSHOT_FILE"
    echo "Cannot revert without a prior snapshot. Use --reset-defaults to restore system defaults."
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would restore settings from $SNAPSHOT_FILE:"
    cat "$SNAPSHOT_FILE"
    exit 0
  fi

  OLD_COLOR="$(jq -r '.color_scheme // empty' "$SNAPSHOT_FILE")"
  OLD_BUTTONS="$(jq -r '.button_layout // empty' "$SNAPSHOT_FILE")"
  OLD_GTK="$(jq -r '.gtk_theme // empty' "$SNAPSHOT_FILE")"
  OLD_WM="$(jq -r '.wm_theme // empty' "$SNAPSHOT_FILE")"
  OLD_ICON="$(jq -r '.icon_theme // empty' "$SNAPSHOT_FILE")"
  OLD_CURSOR="$(jq -r '.cursor_theme // empty' "$SNAPSHOT_FILE")"
  OLD_LIGHT_WP="$(jq -r '.picture_uri // empty' "$SNAPSHOT_FILE")"
  OLD_DARK_WP="$(jq -r '.picture_uri_dark // empty' "$SNAPSHOT_FILE")"
  OLD_SHELL="$(jq -r '.shell_theme // empty' "$SNAPSHOT_FILE")"

  [ -n "$OLD_COLOR" ] && gsettings set org.gnome.desktop.interface color-scheme "$OLD_COLOR"
  [ -n "$OLD_BUTTONS" ] && gsettings set org.gnome.desktop.wm.preferences button-layout "$OLD_BUTTONS"
  [ -n "$OLD_GTK" ] && gsettings set org.gnome.desktop.interface gtk-theme "$OLD_GTK"
  [ -n "$OLD_WM" ] && gsettings set org.gnome.desktop.wm.preferences theme "$OLD_WM" 2>/dev/null || true
  [ -n "$OLD_ICON" ] && gsettings set org.gnome.desktop.interface icon-theme "$OLD_ICON"
  [ -n "$OLD_CURSOR" ] && gsettings set org.gnome.desktop.interface cursor-theme "$OLD_CURSOR"
  [ -n "$OLD_LIGHT_WP" ] && gsettings set org.gnome.desktop.background picture-uri "$OLD_LIGHT_WP"
  [ -n "$OLD_DARK_WP" ] && gsettings set org.gnome.desktop.background picture-uri-dark "$OLD_DARK_WP"
  if [ -n "$OLD_SHELL" ] && [ "$OLD_SHELL" != "not_available" ] && gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings set org.gnome.shell.extensions.user-theme name "$OLD_SHELL" || true
  fi

  gtk4_created=false
  gtk3_created=false
  gtk4_settings_created=false
  gtk3_settings_created=false
  if [ -f "$TRAFFIC_SNAPSHOT_FILE" ] && has_cmd jq; then
    [ "$(jq -r '.gtk4_css_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk4_created=true
    [ "$(jq -r '.gtk3_css_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk3_created=true
    [ "$(jq -r '.gtk4_settings_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk4_settings_created=true
    [ "$(jq -r '.gtk3_settings_existed // false' "$TRAFFIC_SNAPSHOT_FILE")" = "false" ] && gtk3_settings_created=true
  fi

  revert_traffic_lights_css "$GTK4_CSS" "$gtk4_created" "$STATE_DIR/backups/gtk-4.0-gtk.css.bak"
  revert_traffic_lights_css "$GTK3_CSS" "$gtk3_created" "$STATE_DIR/backups/gtk-3.0-gtk.css.bak"
  revert_settings_ini "$GTK4_SETTINGS" "$gtk4_settings_created" "$STATE_DIR/backups/gtk-4.0-settings.ini.bak"
  revert_settings_ini "$GTK3_SETTINGS" "$gtk3_settings_created" "$STATE_DIR/backups/gtk-3.0-settings.ini.bak"
  rm -f "$STATE_DIR/backups/gtk-4.0-gtk.css.bak" "$STATE_DIR/backups/gtk-3.0-gtk.css.bak" "$STATE_DIR/backups/gtk-4.0-settings.ini.bak" "$STATE_DIR/backups/gtk-3.0-settings.ini.bak"
  rm -f "$TRAFFIC_SNAPSHOT_FILE"
  rm -f "$SNAPSHOT_FILE"

  log_success "Appearance reverted to snapshot state."
  exit 0
fi

# 3. Action: RESET TO DEFAULTS
if [ "$ACTION" = "reset_defaults" ]; then
  log_step "Resetting appearance to Kali Linux system defaults..."
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would reset cursor-theme, gtk-theme, icon-theme, button-layout, color-scheme, and wallpapers to system defaults."
    exit 0
  fi

  gsettings reset org.gnome.desktop.interface color-scheme
  gsettings reset org.gnome.desktop.wm.preferences button-layout
  gsettings reset org.gnome.desktop.wm.preferences theme 2>/dev/null || true
  gsettings reset org.gnome.desktop.interface gtk-theme
  gsettings reset org.gnome.desktop.interface icon-theme
  gsettings reset org.gnome.desktop.interface cursor-theme
  gsettings reset org.gnome.desktop.interface cursor-size
  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background picture-uri-dark
  if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings reset org.gnome.shell.extensions.user-theme name 2>/dev/null || true
  fi

  revert_traffic_lights_css "$GTK4_CSS"
  revert_traffic_lights_css "$GTK3_CSS"
  revert_settings_ini "$GTK4_SETTINGS"
  revert_settings_ini "$GTK3_SETTINGS"
  rm -f "$STATE_DIR/backups/gtk-4.0-gtk.css.bak" "$STATE_DIR/backups/gtk-3.0-gtk.css.bak" "$STATE_DIR/backups/gtk-4.0-settings.ini.bak" "$STATE_DIR/backups/gtk-3.0-settings.ini.bak"
  rm -f "$TRAFFIC_SNAPSHOT_FILE"

  log_success "All appearance settings successfully reset to Kali Linux defaults."
  exit 0
fi

# 4. Action: APPLY PROPOSED CHANGES
read_current_settings

if [ "$REQ_TRAFFIC_LIGHTS" = true ]; then
  REQ_BUTTON_LAYOUT="close,minimize,maximize:"
fi

# Determine if any changes requested
CHANGES_COUNT=0
[ -n "$REQ_COLOR_SCHEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_BUTTON_LAYOUT" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_GTK_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_SHELL_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_ICON_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_CURSOR_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_WALLPAPER_MODE" ] && ((CHANGES_COUNT++)) || true
[ "$REQ_TRAFFIC_LIGHTS" = true ] && ((CHANGES_COUNT++)) || true

if [ "$CHANGES_COUNT" -eq 0 ]; then
  log_info "No appearance changes specified."
  echo "Run '$0 --help' to view available options or '--preset macos-dark'."
  exit 0
fi

echo "============================================================"
echo "           macKali Appearance Changes Preview               "
echo "============================================================"
printf "%-22s | %-24s -> %-24s\n" "Setting" "Current Value" "Proposed Value"
echo "------------------------------------------------------------"
[ -n "$REQ_COLOR_SCHEME" ]  && printf "%-22s | %-24s -> %-24s\n" "Color Scheme" "$CUR_COLOR_SCHEME" "$REQ_COLOR_SCHEME"
[ -n "$REQ_BUTTON_LAYOUT" ] && printf "%-22s | %-24s -> %-24s\n" "Window Buttons" "$CUR_BUTTON_LAYOUT" "$REQ_BUTTON_LAYOUT"
[ "$REQ_TRAFFIC_LIGHTS" = true ] && printf "%-22s | %-24s -> %-24s\n" "Traffic Lights" "$CUR_TRAFFIC_LIGHTS" "macOS Top-Left (GTK3 & GTK4)"
[ -n "$REQ_GTK_THEME" ]     && printf "%-22s | %-24s -> %-24s\n" "GTK Theme" "$CUR_GTK_THEME" "$REQ_GTK_THEME"
[ -n "$REQ_SHELL_THEME" ]   && printf "%-22s | %-24s -> %-24s\n" "Shell Theme" "$CUR_SHELL_THEME" "$REQ_SHELL_THEME"
[ -n "$REQ_ICON_THEME" ]    && printf "%-22s | %-24s -> %-24s\n" "Icon Theme" "$CUR_ICON_THEME" "$REQ_ICON_THEME"
[ -n "$REQ_CURSOR_THEME" ]  && printf "%-22s | %-24s -> %-24s\n" "Cursor Theme" "$CUR_CURSOR_THEME" "$REQ_CURSOR_THEME"
[ -n "$REQ_WALLPAPER_MODE" ]&& printf "%-22s | %-24s -> %-24s\n" "Wallpapers" "(Current Desktop)" "macOS $REQ_WALLPAPER_MODE"
echo "============================================================"

# Notice regarding GTK4 / Libadwaita & Traffic Lights
if [ "$REQ_TRAFFIC_LIGHTS" = true ]; then
  echo ""
  log_info "macOS Traffic Lights Integration:"
  echo "  - GTK3 applications: Rendered using WhiteSur GTK theme with authentic traffic lights."
  echo "  - GTK4 / Libadwaita: Scoped CSS applied to ~/.config/gtk-4.0/gtk.css (preserves light/dark mode)."
  echo "  - Controls: Red Close (#ff5f56), Yellow Minimize (#ffbd2e), Green Maximize (#27c93f)."
elif [ -n "$REQ_GTK_THEME" ]; then
  echo ""
  log_info "Libadwaita / GTK4 Notice:"
  echo "  GTK3 applications will render using '$REQ_GTK_THEME'."
  echo "  Modern GNOME/libadwaita applications use their compiled Adwaita stylesheet"
  echo "  and adapt natively according to your selected color-scheme ($REQ_COLOR_SCHEME)."
fi

if [ "$DRY_RUN" = true ]; then
  echo ""
  log_info "[DRY-RUN] Preview complete. No system settings were changed."
  exit 0
fi

# Confirmation prompt
if [ "$CONFIRM" = true ] && [ -t 0 ]; then
  echo ""
  read -r -p "Apply these appearance modifications now? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation aborted by user."
    exit 0
  fi
fi

# Save Per-Setting Baseline Snapshot before applying (never overwrite existing baseline)
if [ ! -f "$SNAPSHOT_FILE" ] && { [ -n "$REQ_COLOR_SCHEME" ] || [ -n "$REQ_WALLPAPER_MODE" ] || [ -n "$REQ_SHELL_THEME" ] || [ -n "$REQ_ICON_THEME" ] || [ -n "$REQ_CURSOR_THEME" ]; }; then
  mkdir -p "$(dirname "$SNAPSHOT_FILE")"
  cat <<EOF > "$SNAPSHOT_FILE"
{
  "timestamp": "$(date +"%Y%m%d_%H%M%S")",
  "color_scheme": "$CUR_COLOR_SCHEME",
  "button_layout": "$CUR_BUTTON_LAYOUT",
  "gtk_theme": "$CUR_GTK_THEME",
  "wm_theme": "$CUR_WM_THEME",
  "shell_theme": "$CUR_SHELL_THEME",
  "icon_theme": "$CUR_ICON_THEME",
  "cursor_theme": "$CUR_CURSOR_THEME",
  "picture_uri": "$CUR_WALLPAPER_LIGHT",
  "picture_uri_dark": "$CUR_WALLPAPER_DARK"
}
EOF
  log_success "Per-setting snapshot saved to $SNAPSHOT_FILE"
fi

# Save Traffic Lights Baseline Snapshot if requested (never overwrite existing baseline)
if [ "$REQ_TRAFFIC_LIGHTS" = true ] && [ ! -f "$TRAFFIC_SNAPSHOT_FILE" ]; then
  mkdir -p "$(dirname "$TRAFFIC_SNAPSHOT_FILE")"
  gtk4_existed=false
  gtk3_existed=false
  gtk4_settings_existed=false
  gtk3_settings_existed=false
  [ -f "$GTK4_CSS" ] && gtk4_existed=true
  [ -f "$GTK3_CSS" ] && gtk3_existed=true
  [ -f "$GTK4_SETTINGS" ] && gtk4_settings_existed=true
  [ -f "$GTK3_SETTINGS" ] && gtk3_settings_existed=true
  cat <<EOF > "$TRAFFIC_SNAPSHOT_FILE"
{
  "timestamp": "$(date +"%Y%m%d_%H%M%S")",
  "previous_button_layout": "$CUR_BUTTON_LAYOUT",
  "previous_gtk_theme": "$CUR_GTK_THEME",
  "previous_wm_theme": "$CUR_WM_THEME",
  "previous_xfwm4_layout": "$CUR_XFWM4_LAYOUT",
  "previous_xfwm4_theme": "$CUR_XFWM4_THEME",
  "gtk4_css_existed": $gtk4_existed,
  "gtk3_css_existed": $gtk3_existed,
  "gtk4_settings_existed": $gtk4_settings_existed,
  "gtk3_settings_existed": $gtk3_settings_existed
}
EOF
fi

# Apply Settings Atomically
log_step "Applying appearance settings..."

if [ -n "$REQ_COLOR_SCHEME" ]; then
  gsettings set org.gnome.desktop.interface color-scheme "$REQ_COLOR_SCHEME" 2>/dev/null || true
  log_success "Set color-scheme: $REQ_COLOR_SCHEME"
fi

if [ -n "$REQ_BUTTON_LAYOUT" ]; then
  gsettings set org.gnome.desktop.wm.preferences button-layout "$REQ_BUTTON_LAYOUT" 2>/dev/null || true
  log_success "Set button-layout: $REQ_BUTTON_LAYOUT"
fi

if [ -n "$REQ_GTK_THEME" ]; then
  if [[ "$REQ_GTK_THEME" == WhiteSur* ]] && [ ! -d "$HOME/.local/share/themes/$REQ_GTK_THEME" ] && [ ! -d "/usr/share/themes/$REQ_GTK_THEME" ]; then
    log_info "Installing WhiteSur GTK themes via gtk-provider.sh..."
    "$REPO_ROOT/scripts/providers/gtk-provider.sh" --install
  fi
  gsettings set org.gnome.desktop.interface gtk-theme "$REQ_GTK_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences theme "$REQ_GTK_THEME" 2>/dev/null || true
  log_success "Set gtk-theme: $REQ_GTK_THEME"
fi

if [ "$REQ_TRAFFIC_LIGHTS" = true ]; then
  if [ ! -d "$HOME/.local/share/themes/WhiteSur-Dark" ] && [ ! -d "/usr/share/themes/WhiteSur-Dark" ]; then
    log_info "Installing WhiteSur GTK themes via gtk-provider.sh..."
    "$REPO_ROOT/scripts/providers/gtk-provider.sh" --install
  fi

  TARGET_THEME="WhiteSur-Dark"
  if [ "$REQ_COLOR_SCHEME" = "prefer-light" ] || { [ -z "$REQ_COLOR_SCHEME" ] && [ "$CUR_COLOR_SCHEME" = "prefer-light" ]; }; then
    TARGET_THEME="WhiteSur-Light"
  fi
  [ -n "$REQ_GTK_THEME" ] && TARGET_THEME="$REQ_GTK_THEME"

  gsettings set org.gnome.desktop.wm.preferences theme "$TARGET_THEME" 2>/dev/null || true

  log_step "Applying macOS traffic lights stylesheet overrides..."
  apply_traffic_lights_css "$GTK4_CSS" "$GTK4_TEMPLATE" "$STATE_DIR/backups/gtk-4.0-gtk.css.bak"
  apply_traffic_lights_css "$GTK3_CSS" "$GTK3_TEMPLATE" "$STATE_DIR/backups/gtk-3.0-gtk.css.bak"

  FORCE_INI_THEME=false
  if [ -n "$REQ_GTK_THEME" ] || [ -n "$REQ_COLOR_SCHEME" ]; then
    FORCE_INI_THEME=true
  fi
  apply_settings_ini "$GTK4_SETTINGS" "$TARGET_THEME" "$STATE_DIR/backups/gtk-4.0-settings.ini.bak" "$FORCE_INI_THEME"
  apply_settings_ini "$GTK3_SETTINGS" "$TARGET_THEME" "$STATE_DIR/backups/gtk-3.0-settings.ini.bak" "$FORCE_INI_THEME"

  if has_cmd xfconf-query; then
    xfconf-query -c xfwm4 -p /general/button_layout -s "CHM|" 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/theme -s "$TARGET_THEME" 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/ThemeName -s "$TARGET_THEME" 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/DecorationLayout -s "close,minimize,maximize:" 2>/dev/null || true
  fi

  log_success "Applied authentic macOS traffic lights to GTK3 & GTK4/Libadwaita applications."
fi

if [ -n "$REQ_SHELL_THEME" ] && gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
  gsettings set org.gnome.shell.extensions.user-theme name "$REQ_SHELL_THEME" 2>/dev/null || true
  log_success "Set shell-theme: $REQ_SHELL_THEME"
fi

if [ -n "$REQ_ICON_THEME" ]; then
  gsettings set org.gnome.desktop.interface icon-theme "$REQ_ICON_THEME" 2>/dev/null || true
  log_success "Set icon-theme: $REQ_ICON_THEME"
fi

if [ -n "$REQ_CURSOR_THEME" ]; then
  # Ensure cursors are installed if requesting WhiteSur-cursors
  if [ "$REQ_CURSOR_THEME" = "WhiteSur-cursors" ] && [ ! -d "$HOME/.local/share/icons/WhiteSur-cursors" ] && [ ! -d "/usr/share/icons/WhiteSur-cursors" ]; then
    log_info "Installing WhiteSur-cursors into ~/.local/share/icons/..."
    "$REPO_ROOT/themes/cursors/install.sh"
  fi
  gsettings set org.gnome.desktop.interface cursor-theme "$REQ_CURSOR_THEME"
  log_success "Set cursor-theme: $REQ_CURSOR_THEME"
fi

if [ "$REQ_WALLPAPER_MODE" = "bundled" ]; then
  "$REPO_ROOT/scripts/providers/wallpaper-provider.sh" --bundled
elif [ "$REQ_WALLPAPER_MODE" = "file" ]; then
  "$REPO_ROOT/scripts/providers/wallpaper-provider.sh" --file "$REQ_WALLPAPER_ARG"
fi

echo ""
echo "============================================================"
log_success "Appearance configuration applied successfully!"
echo "To revert anytime: $0 --revert"
echo "To reset defaults: $0 --reset-defaults"
echo "============================================================"
