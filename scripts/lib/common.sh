#!/usr/bin/env bash
# macKali Common Shell Functions Library

# Color codes
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_BLUE="\033[34m"
COLOR_CYAN="\033[36m"

log_info() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
  echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

log_warn() {
  echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_step() {
  echo -e "${COLOR_BOLD}${COLOR_CYAN}==>${COLOR_RESET} ${COLOR_BOLD}$*${COLOR_RESET}"
}

# Command existence check
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Detect Distribution
detect_os() {
  OS_ID="unknown"
  OS_NAME="Unknown Linux"
  OS_VERSION="unknown"

  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_NAME="${NAME:-Linux}"
    OS_VERSION="${VERSION_ID:-$VERSION}"
  elif has_cmd lsb_release; then
    OS_ID="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
    OS_NAME="$(lsb_release -sd)"
    OS_VERSION="$(lsb_release -sr)"
  fi
}

# Detect Desktop Environment
detect_de() {
  DE_NAME="unknown"
  if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    DE_NAME="$XDG_CURRENT_DESKTOP"
  elif [ -n "$DESKTOP_SESSION" ]; then
    DE_NAME="$DESKTOP_SESSION"
  fi
}

# Detect GNOME Shell Version
detect_gnome_version() {
  GNOME_VERSION="not_detected"
  GNOME_MAJOR_VERSION="0"

  if has_cmd gnome-shell; then
    local raw_ver
    raw_ver="$(gnome-shell --version 2>/dev/null || true)"
    # Extract version string e.g. "50.3" or "46.1"
    GNOME_VERSION="$(echo "$raw_ver" | awk '{print $3}')"
    # Major version before the first dot
    GNOME_MAJOR_VERSION="$(echo "$GNOME_VERSION" | cut -d'.' -f1)"
  fi
}

# Detect Session Type
detect_session_type() {
  SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
}

# Check if running as root
check_not_root() {
  if [ "$EUID" -eq 0 ]; then
    log_warn "Running entire script as root is NOT recommended."
    log_warn "macKali adheres to user-level configuration standards."
    log_warn "Please run as a standard user; sudo will be requested only when strictly necessary."
  fi
}

# Evaluate GNOME Extension Compatibility dynamically across 4 tiers:
# 1. VERIFIED_COMPATIBLE: Explicitly tested in test suite (tested_gnome_versions)
# 2. REPORTED_COMPATIBLE: Declared by upstream manifest or verified live via extensions.gnome.org API
# 3. UNSUPPORTED: Below minimum supported version or deprecated
# 4. COMPATIBILITY_UNKNOWN: Target GNOME is newer than manifest with no network confirmation
evaluate_extension_compat() {
  local uuid="$1"
  local manifest="$2"
  local target_major="${3:-$GNOME_MAJOR_VERSION}"
  local allow_online="${4:-false}"

  COMPAT_STATUS="COMPATIBILITY_UNKNOWN"
  COMPAT_DETAILS="Compatibility status unverified."
  COMPAT_EGO_VER=""
  COMPAT_EGO_TAG=""

  if [ ! -f "$manifest" ] || ! has_cmd jq; then
    COMPAT_STATUS="COMPATIBILITY_UNKNOWN"
    COMPAT_DETAILS="Manifest file missing or jq not available."
    return 0
  fi

  local min_ver
  min_ver="$(jq -r '.min_gnome_version // "45"' "$manifest")"
  local ego_pk
  ego_pk="$(jq -r '.ego_pk // empty' "$manifest")"

  # Check if version is below minimum supported version
  if [[ "$target_major" =~ ^[0-9]+$ ]] && [[ "$min_ver" =~ ^[0-9]+$ ]]; then
    if [ "$target_major" -lt "$min_ver" ]; then
      COMPAT_STATUS="UNSUPPORTED"
      COMPAT_DETAILS="GNOME $target_major is below minimum required version ($min_ver)."
      return 0
    fi
  fi

  # Check 1: Explicitly tested version in macKali test suite
  local is_tested
  is_tested="$(jq --arg v "$target_major" '.tested_gnome_versions // [] | index($v)' "$manifest")"
  if [ "$is_tested" != "null" ]; then
    COMPAT_STATUS="VERIFIED_COMPATIBLE"
    COMPAT_EGO_VER="$(jq -r '.ego_version // empty' "$manifest")"
    COMPAT_EGO_TAG="$(jq -r '.ego_download_tag // empty' "$manifest")"
    COMPAT_DETAILS="Verified compatible — Regression tested on this system."
    return 0
  fi

  # Check 2: Declared in supported_gnome_versions by upstream
  local is_supported
  is_supported="$(jq --arg v "$target_major" '.supported_gnome_versions // [] | index($v)' "$manifest")"
  if [ "$is_supported" != "null" ]; then
    COMPAT_STATUS="REPORTED_COMPATIBLE"
    COMPAT_EGO_VER="$(jq -r '.ego_version // empty' "$manifest")"
    COMPAT_EGO_TAG="$(jq -r '.ego_download_tag // empty' "$manifest")"
    COMPAT_DETAILS="Reported compatible — Declared by upstream release, but untested on this system."
    return 0
  fi

  # Check 3: Live query to extensions.gnome.org API if allowed
  if [ "$allow_online" = true ] && [ -n "$ego_pk" ] && has_cmd curl; then
    local ego_url="https://extensions.gnome.org/extension-info/?pk=${ego_pk}&shell_version=${target_major}"
    local resp
    resp="$(curl -fsSL --max-time 3 "$ego_url" 2>/dev/null || true)"
    if [ -n "$resp" ]; then
      local online_v online_tag
      online_v="$(echo "$resp" | jq -r '.version // empty' 2>/dev/null || true)"
      local dl_path
      dl_path="$(echo "$resp" | jq -r '.download_url // empty' 2>/dev/null || true)"
      online_tag="$(echo "$dl_path" | grep -oP 'version_tag=\K[0-9]+' || true)"

      if [ -n "$online_v" ] && [ -n "$online_tag" ]; then
        COMPAT_STATUS="REPORTED_COMPATIBLE"
        COMPAT_EGO_VER="$online_v"
        COMPAT_EGO_TAG="$online_tag"
        COMPAT_DETAILS="Reported compatible — Dynamically confirmed via extensions.gnome.org release v$online_v."
        return 0
      fi
    fi
  fi

  # Check 4: Version is newer than latest in manifest -> COMPATIBILITY_UNKNOWN
  COMPAT_STATUS="COMPATIBILITY_UNKNOWN"
  COMPAT_DETAILS="Compatibility unknown — GNOME $target_major is newer than local manifests (requires verification)."
  return 0
}

# Detect GNOME Version Shifts after system rolling updates
detect_version_shift() {
  local state_file="$1"
  VERSION_SHIFT_DETECTED=false
  RECORDED_GNOME_VER=""

  if [ -f "$state_file" ] && has_cmd jq; then
    RECORDED_GNOME_VER="$(jq -r '._environment.gnome_version // empty' "$state_file" 2>/dev/null || true)"
    if [ -n "$RECORDED_GNOME_VER" ] && [ "$RECORDED_GNOME_VER" != "null" ]; then
      if [ "$RECORDED_GNOME_VER" != "$GNOME_VERSION" ]; then
        VERSION_SHIFT_DETECTED=true
      fi
    fi
  fi
}
