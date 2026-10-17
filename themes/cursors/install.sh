#!/usr/bin/env bash
set -e

# Determine directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
THEME_NAME="WhiteSur-cursors"

ROOT_UID=0
INSTALL_MODE="auto" # auto, user, system, uninstall

# Parse command line flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --system|-s)
      INSTALL_MODE="system"
      shift
      ;;
    --user|-u)
      INSTALL_MODE="user"
      shift
      ;;
    --uninstall)
      INSTALL_MODE="uninstall"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo "Install or remove the WhiteSur cursor theme."
      echo ""
      echo "Options:"
      echo "  -u, --user       Install to user icons directory (~/.local/share/icons)"
      echo "  -s, --system     Install to system icons directory (/usr/share/icons, requires root)"
      echo "      --uninstall  Remove previously installed WhiteSur cursor theme"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

# Handle uninstall
if [ "$INSTALL_MODE" = "uninstall" ]; then
  echo "Removing $THEME_NAME..."
  if [ -d "$HOME/.local/share/icons/$THEME_NAME" ]; then
    rm -rf "$HOME/.local/share/icons/$THEME_NAME"
    echo "Removed user theme from $HOME/.local/share/icons/$THEME_NAME"
  fi
  if [ -L "$HOME/.icons/$THEME_NAME" ] || [ -d "$HOME/.icons/$THEME_NAME" ]; then
    rm -rf "$HOME/.icons/$THEME_NAME"
  fi
  if [ -f "$HOME/.icons/default/index.theme" ]; then
    if grep -q "Inherits=$THEME_NAME" "$HOME/.icons/default/index.theme" 2>/dev/null; then
      rm -f "$HOME/.icons/default/index.theme"
    fi
  fi
  if [ -d "/usr/share/icons/$THEME_NAME" ]; then
    if [ "$UID" -eq "$ROOT_UID" ]; then
      rm -rf "/usr/share/icons/$THEME_NAME"
      echo "Removed system theme from /usr/share/icons/$THEME_NAME"
    else
      echo "System theme found at /usr/share/icons/$THEME_NAME, but root privileges are needed to remove it."
    fi
  fi
  echo "Uninstall finished."
  exit 0
fi

# Determine target directory
if [ "$INSTALL_MODE" = "system" ] || { [ "$INSTALL_MODE" = "auto" ] && [ "$UID" -eq "$ROOT_UID" ]; }; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="$HOME/.local/share/icons"
fi

# Verify distribution files exist
if [ ! -d "$DIST_DIR" ] || [ ! -d "$DIST_DIR/cursors" ]; then
  echo "Error: Compiled cursor directory not found at $DIST_DIR." >&2
  echo "Please compile cursors first by running: $SCRIPT_DIR/build.sh" >&2
  exit 1
fi

TARGET_DIR="$DEST_DIR/$THEME_NAME"
mkdir -p "$DEST_DIR"

if [ -d "$TARGET_DIR" ]; then
  echo "Removing existing cursor directory at $TARGET_DIR..."
  rm -rf "$TARGET_DIR"
fi

echo "Installing $THEME_NAME to $TARGET_DIR..."
cp -pr "$DIST_DIR" "$TARGET_DIR"

# If installing for user, also configure ~/.icons and default inheritance for X11/Qt/GTK/Electron
if [ "$DEST_DIR" = "$HOME/.local/share/icons" ]; then
  mkdir -p "$HOME/.icons"
  if [ ! -e "$HOME/.icons/$THEME_NAME" ]; then
    ln -sfn "$TARGET_DIR" "$HOME/.icons/$THEME_NAME"
  fi

  mkdir -p "$HOME/.icons/default"
  cat <<EOF > "$HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$THEME_NAME
EOF

  for v in 3.0 4.0; do
    ini="$HOME/.config/gtk-$v/settings.ini"
    if [ -f "$ini" ]; then
      python3 -c "
import configparser
p = '$ini'
cfg = configparser.ConfigParser()
cfg.read(p)
if not cfg.has_section('Settings'):
    cfg.add_section('Settings')
cfg.set('Settings', 'gtk-cursor-theme-name', '$THEME_NAME')
cfg.set('Settings', 'gtk-cursor-theme-size', '24')
with open(p, 'w') as f:
    cfg.write(f, space_around_delimiters=False)
" 2>/dev/null || true
    fi
  done

  mkdir -p "$HOME"
  if [ -f "$HOME/.Xresources" ]; then
    sed -i '/Xcursor\.theme/d' "$HOME/.Xresources" 2>/dev/null || true
    sed -i '/Xcursor\.size/d' "$HOME/.Xresources" 2>/dev/null || true
  fi
  echo "Xcursor.theme: $THEME_NAME" >> "$HOME/.Xresources"
  echo "Xcursor.size: 24" >> "$HOME/.Xresources"
  if command -v xrdb >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
  fi
fi

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface cursor-theme "$THEME_NAME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
fi

echo "Finished installing $THEME_NAME."
