#!/usr/bin/env bash
# macKali: Main installation entry point
# Preserves legacy ./install.sh cursor installation while supporting new modular features

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If invoked with macKali specific options, delegate to appropriate script
case "$1" in
  --interactive|-i)
    shift
    exec "$SCRIPT_DIR/scripts/tui-installer.sh" "$@"
    ;;
  --check-update|--check-updates)
    shift
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/scripts/lib/common.sh"
    REPO_ROOT="$SCRIPT_DIR"
    check_for_updates 6 "check" "$@"
    exit 0
    ;;
  --check|--preset|--dry-run|--backup|--appearance|--wallpaper|--mode|--extensions|--dock-only|--with-magic-lamp|--with-wobbly|--with-cube|--no-update-check)
    exec "$SCRIPT_DIR/scripts/install.sh" "$@"
    ;;
  --uninstall|--reset-defaults|--purge)
    exec "$SCRIPT_DIR/scripts/uninstall.sh" "$@"
    ;;
  --all)
    shift
    exec "$SCRIPT_DIR/scripts/install.sh" "$@"
    ;;
  --help|-h)
    echo "macKali Installation Entry Point"
    echo "================================"
    echo "Legacy Usage (Cursor Installation):"
    echo "  $0                  Install WhiteSur cursors to ~/.local/share/icons"
    echo "  sudo $0 --system    Install WhiteSur cursors system-wide"
    echo "  $0 --uninstall      Uninstall WhiteSur cursors"
    echo ""
    echo "macKali Modular Customization Usage:"
    echo "  $0 --interactive, -i Run the interactive terminal customization wizard (TUI)"
    echo "  $0 --check          Check system and GNOME extension compatibility"
    echo "  $0 --check-update   Check official GitHub releases for newer version"
    echo "  $0 --no-update-check Skip online release update check"
    echo "  $0 --preset <name>  Run macKali installer with preset (minimal, balanced, full)"
    echo "  $0 --backup         Create desktop backup before installing"
    echo "  $0 --dry-run        Simulate installation without making changes"
    echo ""
    echo "Advanced installer: ./scripts/install.sh --help"
    exit 0
    ;;
  *)
    # Default legacy behavior: install cursors via themes/cursors/install.sh
    echo "Running macKali cursor installer..."
    "$SCRIPT_DIR/themes/cursors/install.sh" "$@"
    echo ""
    echo "Note: macKali is now a modular macOS customization suite for Kali Linux."
    echo "To test system compatibility or explore presets, run: ./scripts/compat-check.sh"
    ;;
esac
