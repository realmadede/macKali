#!/usr/bin/env bash
# ==============================================================================
# macKali Website Static Build & Assembly Engine
# Compiles and validates a self-contained static distribution in website/dist/
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"

# Terminal Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_CYAN="\033[36m"
C_YELLOW="\033[33m"
C_RED="\033[31m"

log_info() { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()   { echo -e "${C_GREEN}[ OK ]${C_RESET} $*"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_err()  { echo -e "${C_RED}[FAIL]${C_RESET} $*" >&2; }

print_banner() {
  echo -e "${C_BOLD}============================================================${C_RESET}"
  echo -e "${C_BOLD}           macKali Static Website Build Engine              ${C_RESET}"
  echo -e "${C_BOLD}============================================================${C_RESET}"
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Builds a self-contained, production-ready static website distribution.

Options:
  -c, --clean     Clean the output directory before building
  -v, --validate  Perform strict internal asset reference validation (default)
  -h, --help      Display this help message and exit

Output:
  Generated static site is written to: website/dist/
EOF
}

# Parse options
CLEAN=true
VALIDATE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--clean)
      CLEAN=true
      shift
      ;;
    -v|--validate)
      VALIDATE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_err "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

print_banner

# Step 1: Clean and prepare destination
if [ "$CLEAN" = true ] && [ -d "$DIST_DIR" ]; then
  log_info "Cleaning previous build output: $DIST_DIR"
  rm -rf "$DIST_DIR"
fi

mkdir -p "$DIST_DIR/assets"
log_ok "Created output directory: $DIST_DIR"

# Step 2: Copy static web sources
log_info "Assembling static site sources..."

declare -a SOURCE_FILES=(
  "index.html"
  "404.html"
  "styles.css"
  "script.js"
  "favicon.svg"
  "robots.txt"
  "sitemap.xml"
)

for f in "${SOURCE_FILES[@]}"; do
  if [ ! -f "$SCRIPT_DIR/$f" ]; then
    log_err "Required source file missing: $SCRIPT_DIR/$f"
    exit 1
  fi
  cp -p "$SCRIPT_DIR/$f" "$DIST_DIR/$f"
done
log_ok "Copied ${#SOURCE_FILES[@]} core website files"

# Copy search console verification files if present
for vfile in "$SCRIPT_DIR"/google*.html; do
  if [ -f "$vfile" ]; then
    cp -p "$vfile" "$DIST_DIR/"
    log_ok "Bundled search verification: $(basename "$vfile")"
  fi
done

# Step 3: Copy authentic project visual assets
log_info "Bundling authentic project visual assets..."

declare -A ASSET_MAP=(
  ["preview.png"]="$DIST_DIR/assets/preview.png"
  ["macOS-macKali-Light.png"]="$DIST_DIR/assets/macOS-macKali-Light.png"
  ["macOS-macKali-Dark.png"]="$DIST_DIR/assets/macOS-macKali-Dark.png"
)

for asset in "${!ASSET_MAP[@]}"; do
  dest="${ASSET_MAP[$asset]}"
  if [ -f "$SCRIPT_DIR/assets/$asset" ]; then
    src="$SCRIPT_DIR/assets/$asset"
  elif [ -f "$REPO_ROOT/assets/$asset" ]; then
    src="$REPO_ROOT/assets/$asset"
  elif [ -f "$REPO_ROOT/themes/wallpapers/$asset" ]; then
    src="$REPO_ROOT/themes/wallpapers/$asset"
  else
    log_err "Required asset not found: $asset"
    exit 1
  fi
  cp -p "$src" "$dest"
  log_info "  -> Bundled $(basename "$src") ($(du -h "$src" | awk '{print $1}'))"
done
log_ok "Visual assets successfully bundled into dist/assets/"

# Step 4: Validate distribution integrity
if [ "$VALIDATE" = true ]; then
  log_info "Validating distribution integrity..."

  # 1. Check all required distribution files exist and are non-empty
  declare -a EXPECTED_DIST_FILES=(
    "index.html"
    "404.html"
    "styles.css"
    "script.js"
    "favicon.svg"
    "robots.txt"
    "sitemap.xml"
    "assets/preview.png"
    "assets/macOS-macKali-Light.png"
    "assets/macOS-macKali-Dark.png"
  )

  for file in "${EXPECTED_DIST_FILES[@]}"; do
    target="$DIST_DIR/$file"
    if [ ! -f "$target" ]; then
      log_err "Validation failed: Missing $file in output directory"
      exit 1
    fi
    if [ ! -s "$target" ]; then
      log_err "Validation failed: Empty file $file in output directory"
      exit 1
    fi
  done
  log_ok "All expected distribution files are present and non-empty"

  # 2. Check HTML internal references in index.html
  log_info "Checking internal references in index.html..."
  python3 - <<PYEOF
import re, os, sys

dist_dir = """$DIST_DIR"""
index_path = os.path.join(dist_dir, "index.html")

with open(index_path, "r", encoding="utf-8") as f:
    content = f.read()

# Extract relative local asset and link references
patterns = [
    r'href=["\'](styles\.css|favicon\.svg|index\.html|404\.html)["\']',
    r'src=["\'](script\.js|favicon\.svg|assets/[^"\']+)["\']'
]

checked = set()
for pat in patterns:
    for match in re.finditer(pat, content):
        rel = match.group(1)
        if rel in checked or rel.startswith(("http://", "https://", "#", "mailto:")):
            continue
        checked.add(rel)
        target_path = os.path.join(dist_dir, rel)
        if not os.path.exists(target_path):
            print(f"ERROR: Referenced resource not found: {rel} (resolved to {target_path})", file=sys.stderr)
            sys.exit(1)

print(f"Verified {len(checked)} internal asset references in index.html successfully.")
PYEOF
  log_ok "HTML internal references verified successfully"
fi

# Step 5: Summary
TOTAL_SIZE="$(du -sh "$DIST_DIR" | awk '{print $1}')"
FILE_COUNT="$(find "$DIST_DIR" -type f | wc -l)"

echo -e "${C_BOLD}============================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}Build Succeeded!${C_RESET}"
echo -e "  Output Directory:  ${C_CYAN}$DIST_DIR${C_RESET}"
echo -e "  Total Files:       ${C_BOLD}$FILE_COUNT${C_RESET}"
echo -e "  Total Size:        ${C_BOLD}$TOTAL_SIZE${C_RESET}"
echo -e "  Local Preview:     ${C_CYAN}python3 -m http.server 8000 -d website/dist${C_RESET}"
echo -e "${C_BOLD}============================================================${C_RESET}"
exit 0
