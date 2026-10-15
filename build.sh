#!/usr/bin/env bash
# macKali: Cursor build entry point (Backward-compatible wrapper)
# Preserves legacy ./build.sh workflow while delegating to themes/cursors/build.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$SCRIPT_DIR/themes/cursors/build.sh" ]; then
  echo "Error: themes/cursors/build.sh not found." >&2
  exit 1
fi

exec "$SCRIPT_DIR/themes/cursors/build.sh" "$@"
