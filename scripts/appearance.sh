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
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"

DRY_RUN=false
CONFIRM=true
ACTION="apply" # apply, revert, reset_defaults, status

# Requested appearance changes
REQ_COLOR_SCHEME=""
REQ_BUTTON_LAYOUT=""
REQ_GTK_THEME=""
REQ_SHELL_THEME=""
REQ_ICON_THEME=""
REQ_CURSOR_THEME=""
REQ_WALLPAPER_MODE="" # bundled, file, url
REQ_WALLPAPER_ARG=""

print_usage() {
  echo "macKali Appearance Manager"
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Appearance Configuration Options:"
  echo "  --mode [dark|light|auto]      Set GNOME color-scheme ('prefer-dark', 'prefer-light', 'default')"
  echo "  --buttons [left|right]        Set window button layout (left: traffic lights, right: Kali default)"
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
        left|mac|macos) REQ_BUTTON_LAYOUT="close,minimize,maximize:" ;;
        right|kali|default) REQ_BUTTON_LAYOUT="appmenu:minimize,maximize,close" ;;
        *) log_error "Invalid button layout: $2 (choose left or right)"; exit 1 ;;
      esac
      shift 2
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
          ;;
        macos-light)
          REQ_COLOR_SCHEME="prefer-light"
          REQ_BUTTON_LAYOUT="close,minimize,maximize:"
          REQ_GTK_THEME="WhiteSur-Light"
          REQ_SHELL_THEME="WhiteSur-Light"
          REQ_ICON_THEME="WhiteSur"
          REQ_CURSOR_THEME="WhiteSur-cursors"
          REQ_WALLPAPER_MODE="bundled"
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
      ACTION="revert"
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

# Current settings reader
read_current_settings() {
  CUR_COLOR_SCHEME="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || echo "default")"
  CUR_BUTTON_LAYOUT="$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null | tr -d "'" || echo "default")"
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
}

# 1. Action: STATUS
if [ "$ACTION" = "status" ]; then
  read_current_settings
  echo "============================================================"
  echo "               macKali Current Appearance Status            "
  echo "============================================================"
  echo "  - Color Scheme:       $CUR_COLOR_SCHEME"
  echo "  - Window Buttons:     $CUR_BUTTON_LAYOUT"
  echo "  - GTK Theme:          $CUR_GTK_THEME"
  echo "  - Shell Theme:        $CUR_SHELL_THEME"
  echo "  - Icon Theme:         $CUR_ICON_THEME"
  echo "  - Cursor Theme:       $CUR_CURSOR_THEME (size: $CUR_CURSOR_SIZE)"
  echo "  - Wallpaper (Light):  $CUR_WALLPAPER_LIGHT"
  echo "  - Wallpaper (Dark):   $CUR_WALLPAPER_DARK"
  echo "============================================================"
  exit 0
fi

# 2. Action: REVERT
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
  OLD_ICON="$(jq -r '.icon_theme // empty' "$SNAPSHOT_FILE")"
  OLD_CURSOR="$(jq -r '.cursor_theme // empty' "$SNAPSHOT_FILE")"
  OLD_LIGHT_WP="$(jq -r '.picture_uri // empty' "$SNAPSHOT_FILE")"
  OLD_DARK_WP="$(jq -r '.picture_uri_dark // empty' "$SNAPSHOT_FILE")"
  OLD_SHELL="$(jq -r '.shell_theme // empty' "$SNAPSHOT_FILE")"

  [ -n "$OLD_COLOR" ] && gsettings set org.gnome.desktop.interface color-scheme "$OLD_COLOR"
  [ -n "$OLD_BUTTONS" ] && gsettings set org.gnome.desktop.wm.preferences button-layout "$OLD_BUTTONS"
  [ -n "$OLD_GTK" ] && gsettings set org.gnome.desktop.interface gtk-theme "$OLD_GTK"
  [ -n "$OLD_ICON" ] && gsettings set org.gnome.desktop.interface icon-theme "$OLD_ICON"
  [ -n "$OLD_CURSOR" ] && gsettings set org.gnome.desktop.interface cursor-theme "$OLD_CURSOR"
  [ -n "$OLD_LIGHT_WP" ] && gsettings set org.gnome.desktop.background picture-uri "$OLD_LIGHT_WP"
  [ -n "$OLD_DARK_WP" ] && gsettings set org.gnome.desktop.background picture-uri-dark "$OLD_DARK_WP"
  if [ -n "$OLD_SHELL" ] && [ "$OLD_SHELL" != "not_available" ] && gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings set org.gnome.shell.extensions.user-theme name "$OLD_SHELL" || true
  fi

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
  gsettings reset org.gnome.desktop.interface gtk-theme
  gsettings reset org.gnome.desktop.interface icon-theme
  gsettings reset org.gnome.desktop.interface cursor-theme
  gsettings reset org.gnome.desktop.interface cursor-size
  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background picture-uri-dark
  if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings reset org.gnome.shell.extensions.user-theme name 2>/dev/null || true
  fi

  log_success "All appearance settings successfully reset to Kali Linux defaults."
  exit 0
fi

# 4. Action: APPLY PROPOSED CHANGES
read_current_settings

# Determine if any changes requested
CHANGES_COUNT=0
[ -n "$REQ_COLOR_SCHEME" ] && [ "$REQ_COLOR_SCHEME" != "$CUR_COLOR_SCHEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_BUTTON_LAYOUT" ] && [ "$REQ_BUTTON_LAYOUT" != "$CUR_BUTTON_LAYOUT" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_GTK_THEME" ] && [ "$REQ_GTK_THEME" != "$CUR_GTK_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_SHELL_THEME" ] && [ "$REQ_SHELL_THEME" != "$CUR_SHELL_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_ICON_THEME" ] && [ "$REQ_ICON_THEME" != "$CUR_ICON_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_CURSOR_THEME" ] && [ "$REQ_CURSOR_THEME" != "$CUR_CURSOR_THEME" ] && ((CHANGES_COUNT++)) || true
[ -n "$REQ_WALLPAPER_MODE" ] && ((CHANGES_COUNT++)) || true

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
[ -n "$REQ_GTK_THEME" ]     && printf "%-22s | %-24s -> %-24s\n" "GTK Theme" "$CUR_GTK_THEME" "$REQ_GTK_THEME"
[ -n "$REQ_SHELL_THEME" ]   && printf "%-22s | %-24s -> %-24s\n" "Shell Theme" "$CUR_SHELL_THEME" "$REQ_SHELL_THEME"
[ -n "$REQ_ICON_THEME" ]    && printf "%-22s | %-24s -> %-24s\n" "Icon Theme" "$CUR_ICON_THEME" "$REQ_ICON_THEME"
[ -n "$REQ_CURSOR_THEME" ]  && printf "%-22s | %-24s -> %-24s\n" "Cursor Theme" "$CUR_CURSOR_THEME" "$REQ_CURSOR_THEME"
[ -n "$REQ_WALLPAPER_MODE" ]&& printf "%-22s | %-24s -> %-24s\n" "Wallpapers" "(Current Desktop)" "macOS $REQ_WALLPAPER_MODE"
echo "============================================================"

# Notice regarding GTK4 / Libadwaita
if [ -n "$REQ_GTK_THEME" ]; then
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

# Save Per-Setting Snapshot before applying
mkdir -p "$(dirname "$SNAPSHOT_FILE")"
cat <<EOF > "$SNAPSHOT_FILE"
{
  "timestamp": "$(date +"%Y%m%d_%H%M%S")",
  "color_scheme": "$CUR_COLOR_SCHEME",
  "button_layout": "$CUR_BUTTON_LAYOUT",
  "gtk_theme": "$CUR_GTK_THEME",
  "shell_theme": "$CUR_SHELL_THEME",
  "icon_theme": "$CUR_ICON_THEME",
  "cursor_theme": "$CUR_CURSOR_THEME",
  "picture_uri": "$CUR_WALLPAPER_LIGHT",
  "picture_uri_dark": "$CUR_WALLPAPER_DARK"
}
EOF
log_success "Per-setting snapshot saved to $SNAPSHOT_FILE"

# Apply Settings Atomically
log_step "Applying appearance settings..."

if [ -n "$REQ_COLOR_SCHEME" ]; then
  gsettings set org.gnome.desktop.interface color-scheme "$REQ_COLOR_SCHEME"
  log_success "Set color-scheme: $REQ_COLOR_SCHEME"
fi

if [ -n "$REQ_BUTTON_LAYOUT" ]; then
  gsettings set org.gnome.desktop.wm.preferences button-layout "$REQ_BUTTON_LAYOUT"
  log_success "Set button-layout: $REQ_BUTTON_LAYOUT"
fi

if [ -n "$REQ_GTK_THEME" ]; then
  gsettings set org.gnome.desktop.interface gtk-theme "$REQ_GTK_THEME"
  log_success "Set gtk-theme: $REQ_GTK_THEME"
fi

if [ -n "$REQ_SHELL_THEME" ] && gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
  gsettings set org.gnome.shell.extensions.user-theme name "$REQ_SHELL_THEME"
  log_success "Set shell-theme: $REQ_SHELL_THEME"
fi

if [ -n "$REQ_ICON_THEME" ]; then
  gsettings set org.gnome.desktop.interface icon-theme "$REQ_ICON_THEME"
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
