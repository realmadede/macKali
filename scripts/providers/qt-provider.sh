#!/usr/bin/env bash
# macKali Qt / Kvantum Theme Provider
# Handles user-space installation, verification, and configuration of macOS / WhiteSur Qt themes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/common.sh"

KVANTUM_DIR="$HOME/.config/Kvantum"
KVANTUM_CONF="$KVANTUM_DIR/kvantum.kvconfig"
ENVIRONMENT_DIR="$HOME/.config/environment.d"
QT_ENV_CONF="$ENVIRONMENT_DIR/10-mackali-qt.conf"
STATE_DIR="${MACKALI_STATE_DIR:-$HOME/.config/macKali}"
MANIFEST_FILE="$STATE_DIR/file-manifest.json"
QT_STATE_FILE="$STATE_DIR/qt-state.json"
SYS_KVANTUM_DIR="${MACKALI_SYS_KVANTUM_DIR:-/usr/share/Kvantum}"
DRY_RUN=false
ACTION="check"
THEME_NAME="WhiteSurDark"

track_installed_dir() {
  local dpath="$1"
  mkdir -p "$(dirname "$MANIFEST_FILE")"
  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "[]" > "$MANIFEST_FILE"
  fi
  if has_cmd jq; then
    local tmp
    tmp="$(mktemp)"
    jq --arg d "$dpath" '. += [$d] | unique' "$MANIFEST_FILE" > "$tmp" && mv "$tmp" "$MANIFEST_FILE"
  fi
}

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

untrack_manifest_entry() {
  local entry="$1"
  if [ -f "$MANIFEST_FILE" ] && has_cmd jq; then
    local tmp
    tmp="$(mktemp)"
    jq --arg e "$entry" 'map(select(. != $e))' "$MANIFEST_FILE" > "$tmp" && mv "$tmp" "$MANIFEST_FILE"
  fi
}

has_kvantum_engine() {
  if [ -n "${MACKALI_MOCK_KVANTUM_ENGINE:-}" ]; then
    [ "$MACKALI_MOCK_KVANTUM_ENGINE" = "true" ] && return 0 || return 1
  fi
  if has_cmd kvantummanager || has_cmd kvantumpreview; then
    return 0
  fi
  for so in /usr/lib/*/qt*/plugins/styles/*kvantum*.so /usr/lib/qt*/plugins/styles/*kvantum*.so /usr/local/lib/*/qt*/plugins/styles/*kvantum*.so; do
    if [ -f "$so" ]; then
      return 0
    fi
  done
  return 1
}

resolve_theme_resources() {
  local target="$1"
  RESOLVED_KVCONFIG=""
  RESOLVED_SVG=""

  local bundled_dir="$REPO_ROOT/themes/qt/$target"
  if [ -f "$bundled_dir/$target.kvconfig" ] && [ -f "$bundled_dir/$target.svg" ]; then
    RESOLVED_KVCONFIG="$bundled_dir/$target.kvconfig"
    RESOLVED_SVG="$bundled_dir/$target.svg"
    return 0
  fi

  if [ -f "$SYS_KVANTUM_DIR/$target/$target.kvconfig" ] && [ -f "$SYS_KVANTUM_DIR/$target/$target.svg" ]; then
    RESOLVED_KVCONFIG="$SYS_KVANTUM_DIR/$target/$target.kvconfig"
    RESOLVED_SVG="$SYS_KVANTUM_DIR/$target/$target.svg"
    return 0
  fi

  if [ "$target" = "WhiteSur" ] && [ -f "$SYS_KVANTUM_DIR/KvMojaveLight/KvMojaveLight.kvconfig" ] && [ -f "$SYS_KVANTUM_DIR/KvMojaveLight/KvMojaveLight.svg" ]; then
    RESOLVED_KVCONFIG="$SYS_KVANTUM_DIR/KvMojaveLight/KvMojaveLight.kvconfig"
    RESOLVED_SVG="$SYS_KVANTUM_DIR/KvMojaveLight/KvMojaveLight.svg"
    return 0
  elif [ "$target" = "WhiteSurDark" ] && [ -f "$SYS_KVANTUM_DIR/KvMojave/KvMojave.kvconfig" ] && [ -f "$SYS_KVANTUM_DIR/KvMojave/KvMojave.svg" ]; then
    RESOLVED_KVCONFIG="$SYS_KVANTUM_DIR/KvMojave/KvMojave.kvconfig"
    RESOLVED_SVG="$SYS_KVANTUM_DIR/KvMojave/KvMojave.svg"
    return 0
  fi

  if [ -f "$KVANTUM_DIR/$target/$target.kvconfig" ] && [ -f "$KVANTUM_DIR/$target/$target.svg" ]; then
    RESOLVED_KVCONFIG="$KVANTUM_DIR/$target/$target.kvconfig"
    RESOLVED_SVG="$KVANTUM_DIR/$target/$target.svg"
    return 0
  fi

  return 1
}

init_qt_baseline() {
  mkdir -p "$STATE_DIR/backups"
  if [ -f "$QT_STATE_FILE" ]; then
    return 0
  fi

  local kvconfig_existed=false
  local env_conf_existed=false
  local dark_dir_existed=false
  local light_dir_existed=false

  if [ -f "$KVANTUM_CONF" ]; then
    kvconfig_existed=true
    cp -p "$KVANTUM_CONF" "$STATE_DIR/backups/kvantum.kvconfig.pre-mackali.bak"
  fi

  if [ -f "$QT_ENV_CONF" ]; then
    env_conf_existed=true
    cp -p "$QT_ENV_CONF" "$STATE_DIR/backups/10-mackali-qt.conf.pre-mackali.bak"
  fi

  if [ -d "$KVANTUM_DIR/WhiteSurDark" ]; then
    dark_dir_existed=true
  fi
  if [ -d "$KVANTUM_DIR/WhiteSur" ]; then
    light_dir_existed=true
  fi

  cat <<EOF > "$QT_STATE_FILE"
{
  "kvconfig_existed": $kvconfig_existed,
  "kvconfig_backup": "$STATE_DIR/backups/kvantum.kvconfig.pre-mackali.bak",
  "qt_env_conf_existed": $env_conf_existed,
  "qt_env_conf_backup": "$STATE_DIR/backups/10-mackali-qt.conf.pre-mackali.bak",
  "whitesur_dark_existed": $dark_dir_existed,
  "whitesur_light_existed": $light_dir_existed,
  "installed_by_mackali": true
}
EOF
}

update_kvantum_conf() {
  local target_file="$1"
  local theme="$2"
  mkdir -p "$(dirname "$target_file")"
  if [ -f "$target_file" ] && has_cmd python3; then
    python3 -c "
import configparser
p = '$target_file'
cfg = configparser.ConfigParser(interpolation=None)
cfg.optionxform = str
cfg.read(p)
if not cfg.has_section('General'):
    cfg.add_section('General')
cfg.set('General', 'theme', '$theme')
with open(p, 'w') as f:
    cfg.write(f, space_around_delimiters=False)
"
  else
    cat <<EOF > "$target_file"
[General]
theme=$theme
EOF
  fi
}

update_qt_env_conf() {
  local target_file="$1"
  mkdir -p "$(dirname "$target_file")"
  if [ -f "$target_file" ] && has_cmd python3; then
    python3 -c "
p = '$target_file'
with open(p, 'r') as f:
    lines = f.readlines()
found = False
new_lines = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith('QT_STYLE_OVERRIDE=') or stripped.startswith('export QT_STYLE_OVERRIDE='):
        new_lines.append('QT_STYLE_OVERRIDE=kvantum\n')
        found = True
    else:
        new_lines.append(line)
if not found:
    if new_lines and not new_lines[-1].endswith('\n'):
        new_lines[-1] += '\n'
    new_lines.append('QT_STYLE_OVERRIDE=kvantum\n')
with open(p, 'w') as f:
    f.writelines(new_lines)
"
  elif [ -f "$target_file" ]; then
    if grep -q "^QT_STYLE_OVERRIDE=" "$target_file" 2>/dev/null; then
      sed -i 's/^QT_STYLE_OVERRIDE=.*/QT_STYLE_OVERRIDE=kvantum/' "$target_file"
    else
      echo "QT_STYLE_OVERRIDE=kvantum" >> "$target_file"
    fi
  else
    cat <<EOF > "$target_file"
# macKali Qt / Kvantum session configuration
QT_STYLE_OVERRIDE=kvantum
EOF
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      ACTION="install"
      shift
      ;;
    --check)
      ACTION="check"
      shift
      ;;
    --uninstall)
      ACTION="uninstall"
      shift
      ;;
    --theme)
      case "$2" in
        dark|WhiteSurDark) THEME_NAME="WhiteSurDark" ;;
        light|WhiteSur) THEME_NAME="WhiteSur" ;;
        *) THEME_NAME="$2" ;;
      esac
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      echo "macKali Qt & Kvantum Theme Provider"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --check              Check if Kvantum and WhiteSur Qt themes are configured"
      echo "  --install            Install WhiteSur Qt themes and configure environment"
      echo "  --uninstall          Remove installed WhiteSur Qt themes and configuration"
      echo "  --theme [dark|light] Select Qt theme variant (default: dark)"
      echo "  --dry-run            Preview operations without writing files"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

check_installed() {
  local found=false
  for theme in WhiteSurDark WhiteSur; do
    if { [ -f "$KVANTUM_DIR/$theme/$theme.kvconfig" ] && [ -f "$KVANTUM_DIR/$theme/$theme.svg" ]; } || \
       { [ -f "$SYS_KVANTUM_DIR/$theme/$theme.kvconfig" ] && [ -f "$SYS_KVANTUM_DIR/$theme/$theme.svg" ]; }; then
      log_success "Found functional Kvantum theme: $theme"
      found=true
    fi
  done
  if has_kvantum_engine; then
    log_success "Found Kvantum engine in system"
  else
    log_info "Kvantum engine not installed (install via: sudo apt install qt6-style-kvantum qt5-style-kvantum)"
  fi
  if [ "$found" = false ]; then
    log_info "No functional WhiteSur Kvantum themes currently installed in $KVANTUM_DIR."
    return 1
  fi
  return 0
}

case "$ACTION" in
  check)
    log_step "Checking for installed WhiteSur Qt & Kvantum themes..."
    check_installed || true
    ;;

  install)
    log_step "Configuring WhiteSur Qt & Kvantum integration ($THEME_NAME)..."
    if [ "$DRY_RUN" = true ]; then
      log_info "[DRY-RUN] Would verify Kvantum engine and complete theme resources for $THEME_NAME"
      log_info "[DRY-RUN] Would install WhiteSur Kvantum theme definitions ($THEME_NAME) to $KVANTUM_DIR"
      log_info "[DRY-RUN] Would preserve pre-existing configuration and write active theme to $KVANTUM_CONF"
      log_info "[DRY-RUN] Would configure session environment in $QT_ENV_CONF (QT_STYLE_OVERRIDE=kvantum)"
      exit 0
    fi

    if ! has_kvantum_engine; then
      log_warn "Kvantum style engine is not installed on this system."
      log_info "Skipping Kvantum Qt override to preserve native Qt rendering. Install via: sudo apt install qt6-style-kvantum qt5-style-kvantum"
      exit 1
    fi

    if ! resolve_theme_resources "$THEME_NAME"; then
      log_warn "Complete Kvantum theme resources (.kvconfig and .svg) for '$THEME_NAME' are not available."
      log_info "Refusing to create placeholder Kvantum theme or enable incomplete Qt styling."
      exit 1
    fi

    init_qt_baseline

    mkdir -p "$KVANTUM_DIR"
    mkdir -p "$ENVIRONMENT_DIR"

    # Install complete theme resources (.kvconfig and .svg) if not already in place
    mkdir -p "$KVANTUM_DIR/$THEME_NAME"
    if [ "$RESOLVED_KVCONFIG" != "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig" ]; then
      cp -p "$RESOLVED_KVCONFIG" "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig"
    fi
    if [ "$RESOLVED_SVG" != "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg" ]; then
      cp -p "$RESOLVED_SVG" "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg"
    fi

    theme_was_preexisting=false
    if [ -f "$QT_STATE_FILE" ] && has_cmd jq; then
      if [ "$THEME_NAME" = "WhiteSurDark" ]; then
        theme_was_preexisting="$(jq -r '.whitesur_dark_existed // false' "$QT_STATE_FILE")"
      elif [ "$THEME_NAME" = "WhiteSur" ]; then
        theme_was_preexisting="$(jq -r '.whitesur_light_existed // false' "$QT_STATE_FILE")"
      fi
    fi

    if [ "$theme_was_preexisting" != "true" ]; then
      track_installed_file "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.kvconfig"
      track_installed_file "$KVANTUM_DIR/$THEME_NAME/$THEME_NAME.svg"
      track_installed_dir "$KVANTUM_DIR/$THEME_NAME"
    fi

    # Set active Kvantum theme while preserving unrelated user keys in kvantum.kvconfig
    update_kvantum_conf "$KVANTUM_CONF" "$THEME_NAME"
    track_installed_file "$KVANTUM_CONF"

    # Configure session environment for Qt apps without forcing QT_QPA_PLATFORM=xcb
    update_qt_env_conf "$QT_ENV_CONF"
    track_installed_file "$QT_ENV_CONF"

    log_success "WhiteSur Qt & Kvantum theme configured with theme: $THEME_NAME"
    log_info "Environment written to $QT_ENV_CONF"
    ;;

  uninstall)
    log_step "Removing WhiteSur Qt & Kvantum configuration..."
    dark_existed=false
    light_existed=false
    kvconfig_existed=false
    kvconfig_backup="$STATE_DIR/backups/kvantum.kvconfig.pre-mackali.bak"
    env_conf_existed=false
    env_conf_backup="$STATE_DIR/backups/10-mackali-qt.conf.pre-mackali.bak"

    if [ -f "$QT_STATE_FILE" ] && has_cmd jq; then
      dark_existed="$(jq -r '.whitesur_dark_existed // false' "$QT_STATE_FILE")"
      light_existed="$(jq -r '.whitesur_light_existed // false' "$QT_STATE_FILE")"
      kvconfig_existed="$(jq -r '.kvconfig_existed // false' "$QT_STATE_FILE")"
      kvconfig_backup="$(jq -r '.kvconfig_backup // empty' "$QT_STATE_FILE")"
      env_conf_existed="$(jq -r '.qt_env_conf_existed // false' "$QT_STATE_FILE")"
      env_conf_backup="$(jq -r '.qt_env_conf_backup // empty' "$QT_STATE_FILE")"
    fi

    for theme in WhiteSurDark WhiteSur; do
      was_pre=false
      [ "$theme" = "WhiteSurDark" ] && [ "$dark_existed" = "true" ] && was_pre=true
      [ "$theme" = "WhiteSur" ] && [ "$light_existed" = "true" ] && was_pre=true

      if [ -d "$KVANTUM_DIR/$theme" ]; then
        if [ "$was_pre" = true ]; then
          log_info "Preserving pre-existing user Kvantum theme: $KVANTUM_DIR/$theme"
        elif [ "$DRY_RUN" = true ]; then
          log_info "[DRY-RUN] Would delete: $KVANTUM_DIR/$theme"
        else
          rm -rf "${KVANTUM_DIR:?}/$theme"
          untrack_manifest_entry "$KVANTUM_DIR/$theme/$theme.kvconfig"
          untrack_manifest_entry "$KVANTUM_DIR/$theme/$theme.svg"
          untrack_manifest_entry "$KVANTUM_DIR/$theme"
          log_success "Removed: $KVANTUM_DIR/$theme"
        fi
      fi
    done

    if [ -f "$QT_ENV_CONF" ]; then
      if [ "$DRY_RUN" = true ]; then
        if [ "$env_conf_existed" = "true" ]; then
          log_info "[DRY-RUN] Would restore pre-existing $QT_ENV_CONF from backup"
        else
          log_info "[DRY-RUN] Would remove: $QT_ENV_CONF"
        fi
      else
        if [ "$env_conf_existed" = "true" ] && [ -n "$env_conf_backup" ] && [ -f "$env_conf_backup" ]; then
          cp -p "$env_conf_backup" "$QT_ENV_CONF"
          rm -f "$env_conf_backup"
          log_success "Restored pre-existing environment configuration: $QT_ENV_CONF"
        else
          rm -f "$QT_ENV_CONF"
          log_success "Removed: $QT_ENV_CONF"
        fi
        untrack_manifest_entry "$QT_ENV_CONF"
      fi
    fi

    if [ -f "$KVANTUM_CONF" ]; then
      if [ "$DRY_RUN" = true ]; then
        if [ "$kvconfig_existed" = "true" ]; then
          log_info "[DRY-RUN] Would restore pre-existing $KVANTUM_CONF from backup"
        else
          log_info "[DRY-RUN] Would remove active theme from: $KVANTUM_CONF"
        fi
      else
        if [ "$kvconfig_existed" = "true" ] && [ -n "$kvconfig_backup" ] && [ -f "$kvconfig_backup" ]; then
          cp -p "$kvconfig_backup" "$KVANTUM_CONF"
          rm -f "$kvconfig_backup"
          log_success "Restored pre-existing Kvantum configuration: $KVANTUM_CONF"
        else
          rm -f "$KVANTUM_CONF"
          log_success "Removed: $KVANTUM_CONF"
        fi
        untrack_manifest_entry "$KVANTUM_CONF"
      fi
    fi

    if [ "$DRY_RUN" != true ]; then
      rm -f "$QT_STATE_FILE"
    fi
    ;;
esac
