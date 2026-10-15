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

echo "Finished..."
echo "To activate cursors in GNOME, run:"
echo "  gsettings set org.gnome.desktop.interface cursor-theme '$THEME_NAME'"
