#!/usr/bin/env bash
# ==============================================================================
# macKali Release Packaging Engine
# Generates deterministic, verified distribution archives with SHA-256 checksums
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

# Default configuration
OUTPUT_DIR="$REPO_ROOT/dist"
CUSTOM_VERSION=""
RUN_VERIFICATION=true

# Parse CLI options
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Packages macKali into a production-ready, standalone distribution archive.

Options:
  -o, --output-dir <DIR>  Output directory for release artifacts (default: dist/)
  -v, --version <VER>     Override release version (default: read from VERSION file)
      --no-check          Skip post-packaging extraction and execution verification
  -h, --help              Show this help message and exit

Artifacts Generated:
  - macKali-v<VERSION>.tar.gz   Clean, standalone distribution archive
  - SHA256SUMS                  SHA-256 checksum manifest
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -v|--version)
      CUSTOM_VERSION="$2"
      shift 2
      ;;
    --no-check)
      RUN_VERIFICATION=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Resolve authoritative version
if [ -n "$CUSTOM_VERSION" ]; then
  RAW_VER="$CUSTOM_VERSION"
else
  RAW_VER="$(get_mackali_version "$REPO_ROOT")"
fi

# Clean version string (strip whitespace and optional leading 'v')
VERSION="${RAW_VER#v}"
VERSION="$(echo "$VERSION" | tr -d '[:space:]')"

if [ -z "$VERSION" ]; then
  log_error "Failed to resolve release version. VERSION file is missing or empty."
  exit 1
fi

PACKAGE_NAME="macKali-v${VERSION}"
ARCHIVE_FILENAME="${PACKAGE_NAME}.tar.gz"
OUTPUT_ARCHIVE="${OUTPUT_DIR}/${ARCHIVE_FILENAME}"
OUTPUT_CHECKSUM="${OUTPUT_DIR}/SHA256SUMS"

echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}            macKali Release Packaging Engine               ${COLOR_RESET}"
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
log_info "Project Version:   ${COLOR_BOLD}v${VERSION}${COLOR_RESET}"
log_info "Target Package:    ${COLOR_CYAN}${PACKAGE_NAME}${COLOR_RESET}"
log_info "Output Directory:  ${COLOR_CYAN}${OUTPUT_DIR}${COLOR_RESET}"
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Step 1: Create isolated staging sandbox
STAGE_ROOT="$(mktemp -d /tmp/mackali-package-stage-XXXXXX)"
STAGE_DIR="${STAGE_ROOT}/${PACKAGE_NAME}"
mkdir -p "$STAGE_DIR"

cleanup() {
  rm -rf "$STAGE_ROOT"
}
trap cleanup EXIT INT TERM

log_step "Assembling standalone release payload..."

# Core files
cp -p "$REPO_ROOT/install.sh" "$STAGE_DIR/install.sh"
cp -p "$REPO_ROOT/VERSION" "$STAGE_DIR/VERSION"
cp -p "$REPO_ROOT/LICENSE" "$STAGE_DIR/LICENSE"
cp -p "$REPO_ROOT/README.md" "$STAGE_DIR/README.md"
cp -p "$REPO_ROOT/CHANGELOG.md" "$STAGE_DIR/CHANGELOG.md"

# Scripts & Providers (excluding any test scratch files)
mkdir -p "$STAGE_DIR/scripts/lib" "$STAGE_DIR/scripts/providers"
cp -p "$REPO_ROOT/scripts/"*.sh "$STAGE_DIR/scripts/"
cp -p "$REPO_ROOT/scripts/lib/"*.sh "$STAGE_DIR/scripts/lib/"
cp -p "$REPO_ROOT/scripts/providers/"*.sh "$STAGE_DIR/scripts/providers/"
[ -f "$REPO_ROOT/scripts/README.md" ] && cp -p "$REPO_ROOT/scripts/README.md" "$STAGE_DIR/scripts/"

# Extensions manifests & presets
mkdir -p "$STAGE_DIR/extensions/manifests" "$STAGE_DIR/extensions/presets"
cp -p "$REPO_ROOT/extensions/manifest-schema.json" "$STAGE_DIR/extensions/"
[ -f "$REPO_ROOT/extensions/README.md" ] && cp -p "$REPO_ROOT/extensions/README.md" "$STAGE_DIR/extensions/"
cp -p "$REPO_ROOT/extensions/manifests/"*.json "$STAGE_DIR/extensions/manifests/"
cp -p "$REPO_ROOT/extensions/presets/"*.json "$STAGE_DIR/extensions/presets/"

# Configuration templates
mkdir -p "$STAGE_DIR/config/animations" "$STAGE_DIR/config/dock" "$STAGE_DIR/config/gnome" "$STAGE_DIR/config/keybindings"
[ -f "$REPO_ROOT/config/README.md" ] && cp -p "$REPO_ROOT/config/README.md" "$STAGE_DIR/config/"
cp -p "$REPO_ROOT/config/animations/"* "$STAGE_DIR/config/animations/" 2>/dev/null || true
cp -p "$REPO_ROOT/config/dock/"* "$STAGE_DIR/config/dock/" 2>/dev/null || true
cp -p "$REPO_ROOT/config/gnome/"* "$STAGE_DIR/config/gnome/" 2>/dev/null || true
cp -p "$REPO_ROOT/config/keybindings/"* "$STAGE_DIR/config/keybindings/" 2>/dev/null || true

# Themes (Wallpapers, Cursors, GTK)
mkdir -p "$STAGE_DIR/themes/wallpapers" "$STAGE_DIR/themes/cursors" "$STAGE_DIR/themes/gtk"
cp -p "$REPO_ROOT/themes/wallpapers/"*.png "$STAGE_DIR/themes/wallpapers/"
cp -rp "$REPO_ROOT/themes/cursors/"* "$STAGE_DIR/themes/cursors/"
cp -rp "$REPO_ROOT/themes/gtk/"* "$STAGE_DIR/themes/gtk/" 2>/dev/null || true

# Assets & Documentation
mkdir -p "$STAGE_DIR/assets" "$STAGE_DIR/docs"
cp -p "$REPO_ROOT/assets/preview.png" "$STAGE_DIR/assets/"
cp -p "$REPO_ROOT/docs/"*.md "$STAGE_DIR/docs/"

# Normalize file and directory permissions for deterministic reproducible archives across any environment/umask
find "$STAGE_DIR" -type d -exec chmod 755 {} +
find "$STAGE_DIR" -type f -exec chmod 644 {} +
chmod 755 "$STAGE_DIR/install.sh"
find "$STAGE_DIR/scripts" -type f -name "*.sh" -exec chmod 755 {} +
find "$STAGE_DIR/themes/cursors" -type f -name "*.sh" -exec chmod 755 {} +

# Clean out any temporary editor or cache files from staging
find "$STAGE_DIR" -type f \( -name ".DS_Store" -o -name "*~" -o -name "*.swp" -o -name "*.swo" \) -delete
find "$STAGE_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

log_success "Staged release payload successfully"

# Step 2: Determine reproducible packaging parameters
log_step "Building deterministic tarball..."

# Determine mtime for reproducible timestamping
MTIME_EPOCH=""
if has_cmd git && [ -d "$REPO_ROOT/.git" ]; then
  MTIME_EPOCH="$(git -C "$REPO_ROOT" log -1 --pretty=%ct 2>/dev/null || true)"
fi
if [ -z "$MTIME_EPOCH" ]; then
  MTIME_EPOCH="$(stat -c %Y "$REPO_ROOT/VERSION" 2>/dev/null || date +%s)"
fi

# Prepare GNU tar flags
TAR_FLAGS=(
  --owner=0
  --group=0
  --numeric-owner
)

if tar --sort=name --version >/dev/null 2>&1; then
  TAR_FLAGS+=(--sort=name)
fi

if tar --clamp-mtime --version >/dev/null 2>&1; then
  TAR_FLAGS+=(--clamp-mtime)
fi

TAR_FLAGS+=(--mtime="@$MTIME_EPOCH")

# Remove prior archive if present
rm -f "$OUTPUT_ARCHIVE"

# Create archive via pipe to gzip -n for bit-for-bit reproducible compression
tar "${TAR_FLAGS[@]}" -cf - -C "$STAGE_ROOT" "$PACKAGE_NAME" | gzip -n -9 > "$OUTPUT_ARCHIVE"
chmod 644 "$OUTPUT_ARCHIVE"

log_success "Created archive: $(basename "$OUTPUT_ARCHIVE")"

# Step 3: Generate SHA-256 checksum manifest
log_step "Generating SHA-256 checksum manifest..."
(
  cd "$OUTPUT_DIR"
  sha256sum "$ARCHIVE_FILENAME" > SHA256SUMS
)
log_success "Generated SHA256SUMS"

# Step 4: Verification
if [ "$RUN_VERIFICATION" = true ]; then
  log_step "Running release archive verification..."

  # 1. Checksum validation
  (
    cd "$OUTPUT_DIR"
    sha256sum -c SHA256SUMS >/dev/null
  )
  log_success "Checksum verification passed"

  # 2. Extract into isolated verification directory
  VERIFY_ROOT="$(mktemp -d /tmp/mackali-verify-XXXXXX)"
  verify_cleanup() {
    rm -rf "$VERIFY_ROOT"
  }
  tar -xzf "$OUTPUT_ARCHIVE" -C "$VERIFY_ROOT"

  VERIFY_DIR="${VERIFY_ROOT}/${PACKAGE_NAME}"

  # 3. Verify required files are present and non-empty
  REQUIRED_FILES=(
    "install.sh"
    "VERSION"
    "LICENSE"
    "README.md"
    "CHANGELOG.md"
    "scripts/install.sh"
    "scripts/tui-installer.sh"
    "scripts/compat-check.sh"
    "scripts/appearance.sh"
    "scripts/backup.sh"
    "scripts/restore.sh"
    "scripts/uninstall.sh"
    "scripts/extensions-manager.sh"
    "scripts/lib/common.sh"
    "scripts/providers/gtk-provider.sh"
    "scripts/providers/icon-provider.sh"
    "themes/wallpapers/macOS-macKali-Light.png"
    "themes/wallpapers/macOS-macKali-Dark.png"
    "themes/cursors/install.sh"
    "extensions/manifests/dash-to-dock.json"
    "extensions/presets/balanced.json"
    "config/dock/dash-to-dock.dconf"
    "assets/preview.png"
    "docs/installation.md"
    "docs/architecture.md"
  )

  for req in "${REQUIRED_FILES[@]}"; do
    if [ ! -s "$VERIFY_DIR/$req" ]; then
      log_error "Validation failed: Missing or empty file in archive: $req"
      verify_cleanup
      exit 1
    fi
  done
  log_success "Verified all ${#REQUIRED_FILES[@]} required core files inside archive"

  # 4. Verify exclusions (development, website, test files MUST NOT exist)
  FORBIDDEN_PATHS=(
    ".git"
    ".github"
    "website"
    "tests"
    "dist"
    "build"
    ".cache"
  )

  for forb in "${FORBIDDEN_PATHS[@]}"; do
    if [ -e "$VERIFY_DIR/$forb" ]; then
      log_error "Validation failed: Excluded path present in archive: $forb"
      verify_cleanup
      exit 1
    fi
  done
  log_success "Verified exclusion of development artifacts (.git, website, tests, etc.)"

  # 5. Verify executable permissions
  EXECUTABLES=(
    "install.sh"
    "scripts/install.sh"
    "scripts/tui-installer.sh"
    "scripts/compat-check.sh"
    "scripts/appearance.sh"
    "scripts/restore.sh"
    "scripts/uninstall.sh"
    "scripts/extensions-manager.sh"
    "themes/cursors/install.sh"
  )

  for exe in "${EXECUTABLES[@]}"; do
    if [ ! -x "$VERIFY_DIR/$exe" ]; then
      log_error "Validation failed: Executable permission missing on: $exe"
      verify_cleanup
      exit 1
    fi
  done
  log_success "Verified executable permissions on all release entry points"

  # 6. Test entry point execution outside of git
  "$VERIFY_DIR/install.sh" --help >/dev/null
  "$VERIFY_DIR/scripts/compat-check.sh" --help >/dev/null
  log_success "Verified standalone execution of root entry points"

  verify_cleanup
fi

# Step 5: Summary
ARCHIVE_SIZE="$(du -h "$OUTPUT_ARCHIVE" | awk '{print $1}')"
ARCHIVE_BYTES="$(stat -c %s "$OUTPUT_ARCHIVE" 2>/dev/null || stat -f %z "$OUTPUT_ARCHIVE")"
ARCHIVE_SHA="$(awk '{print $1}' "$OUTPUT_CHECKSUM")"

echo ""
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN}${COLOR_BOLD}Release Packaging Succeeded!${COLOR_RESET}"
echo -e "  Artifact Name:  ${COLOR_CYAN}${ARCHIVE_FILENAME}${COLOR_RESET}"
echo -e "  Artifact Size:  ${COLOR_BOLD}${ARCHIVE_SIZE}${COLOR_RESET} (${ARCHIVE_BYTES} bytes)"
echo -e "  SHA-256:        ${COLOR_BOLD}${ARCHIVE_SHA}${COLOR_RESET}"
echo -e "  Checksum File:  ${COLOR_CYAN}${OUTPUT_CHECKSUM}${COLOR_RESET}"
echo -e "  Verification:   ${COLOR_GREEN}PASS (All integrity & execution checks passed)${COLOR_RESET}"
echo -e "${COLOR_BOLD}============================================================${COLOR_RESET}"
exit 0
