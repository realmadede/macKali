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

# Retrieve authoritative macKali project version (normalized SemVer, e.g. 1.0.0-rc.1)
get_mackali_version() {
  local search_dir="${1:-${REPO_ROOT:-}}"
  local raw=""
  if [ -n "$search_dir" ] && [ -f "$search_dir/VERSION" ]; then
    raw="$(head -n 1 "$search_dir/VERSION" | tr -d '[:space:]')"
  elif [ -f "${SCRIPT_DIR:-.}/../VERSION" ]; then
    raw="$(head -n 1 "${SCRIPT_DIR:-.}/../VERSION" | tr -d '[:space:]')"
  elif [ -f "./VERSION" ]; then
    raw="$(head -n 1 "./VERSION" | tr -d '[:space:]')"
  elif has_cmd git && [ -d "${search_dir:-.}/.git" ]; then
    raw="$(git -C "${search_dir:-.}" describe --tags --always 2>/dev/null || echo "1.0.0-rc.1")"
  else
    raw="1.0.0-rc.1"
  fi
  echo "${raw#v}"
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

# Compare two SemVer strings (e.g. 1.0.0-rc.1 vs 1.0.0, or 1.0.0 vs 1.0.1)
# Returns 0 (true) if $2 (target/remote) is strictly newer than $1 (current)
is_version_newer() {
  local cur="$1"
  local lat="$2"
  if [ "$cur" = "$lat" ]; then
    return 1
  fi
  if has_cmd python3; then
    python3 -c "
import sys
def parse_ver(v):
    v = v.lstrip('v').strip()
    parts = v.split('-', 1)
    nums = [int(x) if x.isdigit() else 0 for x in parts[0].split('.')]
    is_prerelease = len(parts) > 1
    return (nums, 0 if is_prerelease else 1, parts[1] if is_prerelease else '')

cur = parse_ver('$cur')
lat = parse_ver('$lat')
sys.exit(0 if cur < lat else 1)
" >/dev/null 2>&1
    return $?
  else
    [ "$cur" != "$lat" ] && return 0 || return 1
  fi
}

# Check GitHub Releases API for upstream updates
# Parameters:
#   $1: timeout_seconds (default: 2)
#   $2: mode ("notify" - only print if update available, "check" - print status always)
#   $3: repo_owner_repo (default: "realmadede/macKali")
#   $4: mock_tag (optional, for testing via $MOCK_LATEST_RELEASE)
check_for_updates() {
  local timeout="${1:-2}"
  local mode="${2:-notify}"
  local repo="${3:-realmadede/macKali}"
  local mock_tag="${4:-${MOCK_LATEST_RELEASE:-}}"

  local current_ver
  current_ver="$(get_mackali_version "${REPO_ROOT:-}")"
  local clean_current="${current_ver#v}"
  local latest_tag=""

  if [ -n "$mock_tag" ]; then
    latest_tag="$mock_tag"
  elif has_cmd curl; then
    local releases_url="https://api.github.com/repos/${repo}/releases?per_page=5"
    local resp
    resp="$(curl -fsSL --max-time "$timeout" -H "Accept: application/vnd.github.v3+json" -H "User-Agent: macKali-Updater" "$releases_url" 2>/dev/null || true)"
    if [ -n "$resp" ] && has_cmd jq; then
      if [[ "$clean_current" == *-* ]]; then
        latest_tag="$(echo "$resp" | jq -r '.[0].tag_name // empty' 2>/dev/null || true)"
      else
        latest_tag="$(echo "$resp" | jq -r 'map(select(.prerelease == false))[0].tag_name // .[0].tag_name // empty' 2>/dev/null || true)"
      fi
    elif [ -n "$resp" ]; then
      latest_tag="$(echo "$resp" | grep -m1 -oP '"tag_name":\s*"\K[^"]+' || true)"
    fi
  fi

  local clean_latest="${latest_tag#v}"

  if [ -z "$clean_latest" ]; then
    if [ "$mode" = "check" ]; then
      log_warn "Could not reach GitHub Releases API to verify updates (offline, unreleased, or rate limited)."
    fi
    return 0
  fi

  if is_version_newer "$clean_current" "$clean_latest"; then
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_YELLOW}============================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_YELLOW}🔔  macKali Update Available!${COLOR_RESET}"
    echo -e "   Current installed:  ${COLOR_BOLD}v${clean_current}${COLOR_RESET}"
    echo -e "   Latest release:     ${COLOR_BOLD}${COLOR_GREEN}v${clean_latest}${COLOR_RESET}"
    echo -e "   To update:          Run ${COLOR_CYAN}git pull${COLOR_RESET} or download from:"
    echo -e "                       ${COLOR_CYAN}https://mackali.madede.workers.dev${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_YELLOW}============================================================${COLOR_RESET}"
    echo ""
    return 0
  fi

  if [ "$mode" = "check" ]; then
    log_success "macKali is up to date (v${clean_current})."
  fi
  return 0
}
