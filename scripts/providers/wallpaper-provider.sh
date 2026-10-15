#!/usr/bin/env bash
# macKali Wallpaper Provider
# Manages light and dark macOS-style wallpapers with local, bundled, and URL support.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/common.sh"

DEST_DIR="$HOME/.local/share/backgrounds/macKali"
MANIFEST_FILE="$HOME/.config/macKali/file-manifest.json"

MODE="bundled"
TARGET_VARIANT="both" # light, dark, both
INPUT_PATH=""
DRY_RUN=false

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

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundled)
      MODE="bundled"
      shift
      ;;
    --file)
      MODE="file"
      INPUT_PATH="$2"
      shift 2
      ;;
    --url)
      MODE="url"
      INPUT_PATH="$2"
      shift 2
      ;;
    --variant)
      TARGET_VARIANT="$2" # light, dark, both
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --reset)
      MODE="reset"
      shift
      ;;
    --help|-h)
      echo "macKali Wallpaper Provider"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --bundled               Apply bundled 4K macOS Light & Dark wallpapers"
      echo "  --file PATH             Set wallpaper from local file path"
      echo "  --url URL               Download and set wallpaper from remote URL"
      echo "  --variant [light|dark|both] Target variant (default: both)"
      echo "  --dry-run               Preview changes without modifying system settings"
      echo "  --reset                 Reset background wallpapers to system defaults"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

# Current wallpaper state
CURRENT_LIGHT=""
CURRENT_DARK=""
if has_cmd gsettings; then
  CURRENT_LIGHT="$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || echo "not set")"
  CURRENT_DARK="$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null || echo "not set")"
fi

if [ "$MODE" = "reset" ]; then
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would reset picture-uri and picture-uri-dark to system defaults."
    exit 0
  fi
  log_info "Resetting wallpapers to Kali system defaults..."
  gsettings reset org.gnome.desktop.background picture-uri
  gsettings reset org.gnome.desktop.background picture-uri-dark
  log_success "Wallpapers reset to system defaults."
  exit 0
fi

LIGHT_TARGET=""
DARK_TARGET=""

case "$MODE" in
  bundled)
    BUNDLED_LIGHT="$REPO_ROOT/themes/wallpapers/macOS-macKali-Light.png"
    BUNDLED_DARK="$REPO_ROOT/themes/wallpapers/macOS-macKali-Dark.png"

    if [ ! -f "$BUNDLED_LIGHT" ] || [ ! -f "$BUNDLED_DARK" ]; then
      log_error "Bundled wallpapers not found in $REPO_ROOT/themes/wallpapers/"
      exit 1
    fi

    mkdir -p "$DEST_DIR"
    cp -p "$BUNDLED_LIGHT" "$DEST_DIR/macOS-macKali-Light.png"
    cp -p "$BUNDLED_DARK" "$DEST_DIR/macOS-macKali-Dark.png"
    track_installed_file "$DEST_DIR/macOS-macKali-Light.png"
    track_installed_file "$DEST_DIR/macOS-macKali-Dark.png"

    LIGHT_TARGET="file://$DEST_DIR/macOS-macKali-Light.png"
    DARK_TARGET="file://$DEST_DIR/macOS-macKali-Dark.png"
    ;;

  file)
    if [ ! -f "$INPUT_PATH" ]; then
      log_error "Specified wallpaper file does not exist: $INPUT_PATH"
      exit 1
    fi
    mkdir -p "$DEST_DIR"
    EXT="${INPUT_PATH##*.}"
    TARGET_NAME="custom-wallpaper-${TARGET_VARIANT}.${EXT}"
    cp -p "$INPUT_PATH" "$DEST_DIR/$TARGET_NAME"
    track_installed_file "$DEST_DIR/$TARGET_NAME"
    FILE_URI="file://$DEST_DIR/$TARGET_NAME"

    if [ "$TARGET_VARIANT" = "light" ]; then
      LIGHT_TARGET="$FILE_URI"
    elif [ "$TARGET_VARIANT" = "dark" ]; then
      DARK_TARGET="$FILE_URI"
    else
      LIGHT_TARGET="$FILE_URI"
      DARK_TARGET="$FILE_URI"
    fi
    ;;

  url)
    if ! has_cmd curl; then
      log_error "curl is required to download remote wallpapers."
      exit 1
    fi
    mkdir -p "$DEST_DIR"
    EXT="${INPUT_PATH##*.}"
    [ -z "$EXT" ] && EXT="png"
    TARGET_NAME="remote-wallpaper-${TARGET_VARIANT}.${EXT}"
    TARGET_FILE="$DEST_DIR/$TARGET_NAME"

    log_info "Downloading wallpaper from $INPUT_PATH..."
    if ! curl -fsSL "$INPUT_PATH" -o "$TARGET_FILE"; then
      log_error "Failed to download wallpaper from $INPUT_PATH"
      exit 1
    fi
    track_installed_file "$TARGET_FILE"
    FILE_URI="file://$TARGET_FILE"

    if [ "$TARGET_VARIANT" = "light" ]; then
      LIGHT_TARGET="$FILE_URI"
    elif [ "$TARGET_VARIANT" = "dark" ]; then
      DARK_TARGET="$FILE_URI"
    else
      LIGHT_TARGET="$FILE_URI"
      DARK_TARGET="$FILE_URI"
    fi
    ;;
esac

echo "============================================================"
echo "               macKali Wallpaper Configuration              "
echo "============================================================"
echo "Current Settings:"
echo "  Light mode URI: $CURRENT_LIGHT"
echo "  Dark mode URI:  $CURRENT_DARK"
echo ""
echo "Proposed Settings:"
[ -n "$LIGHT_TARGET" ] && echo "  New Light URI:  $LIGHT_TARGET"
[ -n "$DARK_TARGET" ]  && echo "  New Dark URI:   $DARK_TARGET"
echo "============================================================"

if [ "$DRY_RUN" = true ]; then
  log_info "[DRY-RUN] Preview mode complete. No system settings modified."
  exit 0
fi

if has_cmd gsettings; then
  if [ -n "$LIGHT_TARGET" ]; then
    gsettings set org.gnome.desktop.background picture-uri "$LIGHT_TARGET"
    log_success "Updated light wallpaper: $LIGHT_TARGET"
  fi
  if [ -n "$DARK_TARGET" ]; then
    gsettings set org.gnome.desktop.background picture-uri-dark "$DARK_TARGET"
    log_success "Updated dark wallpaper: $DARK_TARGET"
  fi
  gsettings set org.gnome.desktop.background picture-options 'zoom'
fi

log_success "Wallpaper configuration applied successfully."
