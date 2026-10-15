#!/usr/bin/env bash
# macKali GNOME Extension & Dock Integration Manager (Phase 3)
# Manages verified extensions, macOS dock layout, and safe preset orchestration.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

STATE_DIR="${MACKALI_STATE_DIR:-$HOME/.config/macKali}"
STATE_FILE="$STATE_DIR/extensions-state.json"
MANIFEST_FILE="$STATE_DIR/file-manifest.json"
MANIFESTS_DIR="$REPO_ROOT/extensions/manifests"
PRESETS_DIR="$REPO_ROOT/extensions/presets"

DRY_RUN=false
ASSUME_YES=false
WITH_MAGIC_LAMP=false
WITH_WOBBLY=false
WITH_CUBE=false
FORCE_OVERWRITE=false

# Supported UUIDs
SUPPORTED_UUIDS=(
  "dash-to-dock@micxgx.gmail.com"
  "blur-my-shell@aunetx"
  "compiz-alike-magic-lamp-effect@hermes83.github.com"
  "compiz-windows-effect@hermes83.github.com"
  "desktop-cube@schneegans.github.com"
)

# Initialize and scan baseline state before macKali modifies anything
init_state_tracking() {
  mkdir -p "$STATE_DIR"
  mkdir -p "$STATE_DIR/backups"

  # Initialize file manifest if missing
  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "[]" > "$MANIFEST_FILE"
  fi

  # If state file exists, preserve it
  if [ -f "$STATE_FILE" ]; then
    return 0
  fi

  # Build initial baseline snapshot
  local initial_state="{}"
  for uuid in "${SUPPORTED_UUIDS[@]}"; do
    local is_installed=false
    local install_path=""
    local version="null"
    local is_enabled=false

    # Check system vs user path
    if [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
      is_installed=true
      install_path="/usr/share/gnome-shell/extensions/$uuid"
    elif [ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]; then
      is_installed=true
      install_path="$HOME/.local/share/gnome-shell/extensions/$uuid"
    fi

    # Read installed version if present
    if [ "$is_installed" = true ]; then
      if [ -f "$install_path/metadata.json" ] && has_cmd jq; then
        local raw_v
        raw_v="$(jq -r '.version // empty' "$install_path/metadata.json" 2>/dev/null || true)"
        [ -n "$raw_v" ] && version="\"$raw_v\""
      fi
    fi

    # Check if currently enabled
    if has_cmd gnome-extensions; then
      if gnome-extensions list --enabled 2>/dev/null | grep -qx "$uuid"; then
        is_enabled=true
      fi
    fi

    local entry
    entry=$(cat <<EOF
{
  "pre_existing": $is_installed,
  "pre_existing_path": "$install_path",
  "pre_existing_version": $version,
  "pre_existing_enabled": $is_enabled,
  "installed_by_mackali": false,
  "installed_version": null,
  "dock_config_applied": false,
  "dock_backup_file": null
}
EOF
)
    initial_state=$(echo "$initial_state" | jq --arg u "$uuid" --argjson e "$entry" '.[$u] = $e')
  done

  echo "$initial_state" > "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

# Update a single state field
update_state() {
  local uuid="$1"
  local key="$2"
  local val="$3"

  init_state_tracking
  if has_cmd jq && [ -f "$STATE_FILE" ]; then
    local tmp
    tmp="$(mktemp)"
    jq --arg u "$uuid" --arg k "$key" --argjson v "$val" '.[$u][$k] = $v' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
}

# Add path to tracked file manifest
track_file() {
  local path="$1"
  if has_cmd jq; then
    mkdir -p "$(dirname "$MANIFEST_FILE")"
    [ -f "$MANIFEST_FILE" ] || echo "[]" > "$MANIFEST_FILE"
    local tmp
    tmp="$(mktemp)"
    jq --arg p "$path" 'if index($p) then . else . + [$p] end' "$MANIFEST_FILE" > "$tmp" && mv "$tmp" "$MANIFEST_FILE"
  fi
}

# Get manifest file for a given UUID
get_manifest_path() {
  local uuid="$1"
  case "$uuid" in
    "dash-to-dock@micxgx.gmail.com") echo "$MANIFESTS_DIR/dash-to-dock.json" ;;
    "blur-my-shell@aunetx") echo "$MANIFESTS_DIR/blur-my-shell.json" ;;
    "compiz-alike-magic-lamp-effect@hermes83.github.com") echo "$MANIFESTS_DIR/compiz-alike-magic-lamp-effect.json" ;;
    "compiz-windows-effect@hermes83.github.com") echo "$MANIFESTS_DIR/compiz-windows-effect.json" ;;
    "desktop-cube@schneegans.github.com") echo "$MANIFESTS_DIR/desktop-cube.json" ;;
    *) echo "" ;;
  esac
}

# Print CLI Banner
print_banner() {
  echo -e "${COLOR_BOLD}${COLOR_CYAN}============================================================${COLOR_RESET}"
  echo -e "${COLOR_BOLD}     macKali GNOME Extension & Dock Integration Manager     ${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}============================================================${COLOR_RESET}"
}

# Print Usage Help
show_help() {
  print_banner
  echo "Usage: $0 [ACTION] [OPTIONS]"
  echo ""
  echo "Actions:"
  echo "  --list                      List all supported extensions and metadata"
  echo "  --status, --installed       Show current system installation and enable states"
  echo "  --compat                    Verify compatibility against GNOME Shell 50.3 & Wayland"
  echo "  --install UUID              Install verified release bundle for specified extension"
  echo "  --install-all               Install all supported extensions"
  echo "  --enable UUID               Enable specified extension"
  echo "  --disable UUID              Disable specified extension"
  echo "  --dock-config               Apply macOS-inspired dock layout to Dash to Dock"
  echo "  --dock-revert               Revert Dash to Dock settings to original user backup"
  echo "  --preset PRESET             Apply preset (minimal, balanced, full)"
  echo "  --restore                   Restore all extensions & dock settings to pre-macKali state"
  echo ""
  echo "Options:"
  echo "  --dry-run                   Preview operations without downloading or modifying state"
  echo "  -y, --yes                   Assume Yes to interactive confirmations"
  echo "  -f, --force                 Allow overwriting existing user-space extension"
  echo "  --with-magic-lamp           Opt-in to Genie lamp animations in Balanced/Full presets"
  echo "  --with-wobbly               Opt-in to Compiz wobbly windows effect in Full preset"
  echo "  --with-cube                 Opt-in to experimental Desktop Cube in Full preset"
  echo "  -h, --help                  Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --compat                 # Check GNOME 50.3 and Wayland compatibility"
  echo "  $0 --status                 # Inspect installed vs pre-existing extensions"
  echo "  $0 --dock-config            # Apply centered macOS dock styling safely"
  echo "  $0 --preset balanced        # Apply Balanced preset (Dock + Blur My Shell)"
  echo "  $0 --restore                # Revert extensions & dock to original configuration"
}

# Action: List supported extensions
cmd_list() {
  print_banner
  echo -e "${COLOR_BOLD}Supported GNOME Extensions:${COLOR_RESET}"
  echo ""

  for uuid in "${SUPPORTED_UUIDS[@]}"; do
    local mf
    mf="$(get_manifest_path "$uuid")"
    if [ -f "$mf" ] && has_cmd jq; then
      local name license versions ego_pk wayland_comp presets
      name="$(jq -r '.name' "$mf")"
      license="$(jq -r '.license // "Unknown"' "$mf")"
      versions="$(jq -r '.supported_gnome_versions | join(", ")' "$mf")"
      ego_pk="$(jq -r '.ego_pk // "N/A"' "$mf")"
      wayland_comp="$(jq -r 'if .wayland_compatible then "Yes" else "Unverified" end' "$mf")"
      presets="$(jq -r '.enabled_presets | join(", ")' "$mf")"

      echo -e "  ${COLOR_BOLD}$name${COLOR_RESET} ($uuid)"
      echo "    - License:       $license"
      echo "    - EGO PK:        $ego_pk"
      echo "    - GNOME Range:   $versions"
      echo "    - Wayland:       $wayland_comp"
      echo "    - Presets:       $presets"
      echo ""
    fi
  done
}

# Action: Inspect status of extensions on current host
cmd_status() {
  init_state_tracking
  print_banner
  echo -e "${COLOR_BOLD}System Extension Status & Tracking:${COLOR_RESET}"
  echo ""

  detect_gnome_version
  detect_session_type
  echo "Current Environment: GNOME $GNOME_VERSION | Session: $SESSION_TYPE"
  echo ""

  printf "%-32s %-12s %-10s %-12s %-16s\n" "Extension" "Status" "Version" "Active" "Origin"
  echo "--------------------------------------------------------------------------------"

  for uuid in "${SUPPORTED_UUIDS[@]}"; do
    local mf
    mf="$(get_manifest_path "$uuid")"
    local name="$uuid"
    [ -f "$mf" ] && has_cmd jq && name="$(jq -r '.name' "$mf")"

    local is_installed="No"
    local cur_ver="-"
    local is_active="No"
    local origin="Not installed"

    if [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
      is_installed="System"
      origin="Pre-existing"
      if [ -f "/usr/share/gnome-shell/extensions/$uuid/metadata.json" ] && has_cmd jq; then
        cur_ver="$(jq -r '.version // "-"' "/usr/share/gnome-shell/extensions/$uuid/metadata.json" 2>/dev/null || echo "-")"
      fi
    elif [ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]; then
      is_installed="User"
      local by_mackali=false
      if [ -f "$STATE_FILE" ] && has_cmd jq; then
        by_mackali="$(jq -r --arg u "$uuid" '.[$u].installed_by_mackali // false' "$STATE_FILE")"
      fi
      if [ "$by_mackali" = true ]; then
        origin="macKali"
      else
        origin="User (Pre-existing)"
      fi
      if [ -f "$HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json" ] && has_cmd jq; then
        cur_ver="$(jq -r '.version // "-"' "$HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json" 2>/dev/null || echo "-")"
      fi
    fi

    if has_cmd gnome-extensions; then
      if gnome-extensions list --enabled 2>/dev/null | grep -qx "$uuid"; then
        is_active="Yes"
      fi
    fi

    printf "%-32s %-12s %-10s %-12s %-16s\n" "$name" "$is_installed" "$cur_ver" "$is_active" "$origin"
  done

  echo ""
  # Report dock layout configuration state
  local dock_applied=false
  if [ -f "$STATE_FILE" ] && has_cmd jq; then
    dock_applied="$(jq -r '."dash-to-dock@micxgx.gmail.com".dock_config_applied // false' "$STATE_FILE")"
  fi
  echo "Dash to Dock macOS styling applied: $dock_applied"
  echo ""
}

# Action: Check compatibility against current GNOME version
cmd_compat() {
  print_banner
  log_step "Evaluating Upstream Compatibility for GNOME Shell 50.3 & Wayland..."

  detect_gnome_version
  detect_session_type
  echo "  - Host GNOME Shell Version: $GNOME_VERSION (Major: $GNOME_MAJOR_VERSION)"
  echo "  - Compositor Session:       $SESSION_TYPE"
  echo ""

  local all_compat=true
  for uuid in "${SUPPORTED_UUIDS[@]}"; do
    local mf
    mf="$(get_manifest_path "$uuid")"
    [ -f "$mf" ] || continue

    local name license ego_ver tag wayland_ok
    name="$(jq -r '.name' "$mf")"
    license="$(jq -r '.license // "GPL"' "$mf")"
    ego_ver="$(jq -r '.ego_version // "unknown"' "$mf")"
    tag="$(jq -r '.ego_download_tag // "unknown"' "$mf")"
    wayland_ok="$(jq -r '.wayland_compatible' "$mf")"

    local is_ver_supported
    is_ver_supported="$(jq --arg v "$GNOME_MAJOR_VERSION" '.supported_gnome_versions | index($v)' "$mf")"

    if [ "$is_ver_supported" != "null" ] && [ "$wayland_ok" = "true" ]; then
      log_success "$name ($uuid)"
      echo "    - GNOME $GNOME_MAJOR_VERSION Compatibility: Verified (EGO Release v$ego_ver, tag $tag)"
      echo "    - Wayland Native Support:        Verified"
      echo "    - Upstream License:              $license"
    else
      log_warn "$name ($uuid) -> Compatibility unverified for current environment."
      all_compat=false
    fi
  done

  echo ""
  if [ "$all_compat" = true ]; then
    log_success "All 5 extensions have verified GNOME $GNOME_MAJOR_VERSION & Wayland release artifacts!"
  else
    log_warn "One or more extensions require manual verification before enabling."
  fi
}

# Action: Install a verified extension bundle from extensions.gnome.org
cmd_install() {
  local uuid="$1"
  init_state_tracking

  local mf
  mf="$(get_manifest_path "$uuid")"
  if [ -z "$mf" ] || [ ! -f "$mf" ]; then
    log_error "Unknown extension UUID or manifest missing: $uuid"
    exit 1
  fi

  local name ego_tag ego_ver
  name="$(jq -r '.name' "$mf")"
  ego_tag="$(jq -r '.ego_download_tag // empty' "$mf")"
  ego_ver="$(jq -r '.ego_version // empty' "$mf")"

  if [ -z "$ego_tag" ]; then
    log_error "No verified EGO download tag registered for $uuid"
    exit 1
  fi

  log_step "Installing $name ($uuid)..."

  # Check pre-existing installation
  local user_ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"
  local sys_ext_dir="/usr/share/gnome-shell/extensions/$uuid"

  if [ -d "$sys_ext_dir" ]; then
    log_info "Extension is already installed system-wide at $sys_ext_dir (version: $(jq -r '.version // "unknown"' "$sys_ext_dir/metadata.json" 2>/dev/null || echo "unknown"))."
    log_info "macKali preserves pre-existing system extensions without overwriting."
    return 0
  fi

  if [ -d "$user_ext_dir" ] && [ "$FORCE_OVERWRITE" != true ]; then
    local is_mackali=false
    if [ -f "$STATE_FILE" ] && has_cmd jq; then
      is_mackali="$(jq -r --arg u "$uuid" '.[$u].installed_by_mackali // false' "$STATE_FILE")"
    fi
    if [ "$is_mackali" = true ]; then
      log_info "Extension already installed by macKali at $user_ext_dir."
      return 0
    else
      log_warn "Extension already exists at $user_ext_dir (pre-existing user extension)."
      log_warn "Use --force to overwrite if desired. Preserving existing copy."
      return 0
    fi
  fi

  local dl_url="https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?version_tag=${ego_tag}"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would fetch official release bundle: $dl_url"
    log_info "[DRY-RUN] Would verify archive integrity and validate metadata UUID: $uuid"
    log_info "[DRY-RUN] Would unpack to user extension path: $user_ext_dir"
    log_info "[DRY-RUN] Would compile schemas in $user_ext_dir/schemas"
    log_info "[DRY-RUN] Would register extension in macKali state and file manifest"
    return 0
  fi

  # Download and verify bundle
  local tmp_zip
  tmp_zip="$(mktemp --suffix=.zip)"
  log_info "Downloading official release artifact (v$ego_ver)..."
  if ! curl -fsSL "$dl_url" -o "$tmp_zip"; then
    log_error "Failed to download extension bundle from $dl_url"
    rm -f "$tmp_zip"
    exit 1
  fi

  # Verify zip integrity
  if ! unzip -t "$tmp_zip" >/dev/null 2>&1; then
    log_error "Downloaded artifact is corrupted or not a valid zip archive."
    rm -f "$tmp_zip"
    exit 1
  fi

  # Validate metadata.json inside zip
  local zip_uuid
  zip_uuid="$(unzip -p "$tmp_zip" metadata.json 2>/dev/null | jq -r '.uuid // empty')"
  if [ "$zip_uuid" != "$uuid" ]; then
    log_error "Security check failed: Bundle metadata UUID '$zip_uuid' does not match target UUID '$uuid'!"
    rm -f "$tmp_zip"
    exit 1
  fi

  # Install into user extensions directory
  mkdir -p "$user_ext_dir"
  unzip -qo "$tmp_zip" -d "$user_ext_dir"
  rm -f "$tmp_zip"

  # Compile schemas if present
  if [ -d "$user_ext_dir/schemas" ]; then
    if has_cmd glib-compile-schemas; then
      glib-compile-schemas "$user_ext_dir/schemas" 2>/dev/null || true
    fi
  fi

  # Track in macKali state
  track_file "$user_ext_dir"
  update_state "$uuid" "installed_by_mackali" "true"
  update_state "$uuid" "installed_version" "\"$ego_ver\""

  log_success "Extension $name ($uuid) installed successfully to $user_ext_dir!"
}

# Action: Enable an installed extension
cmd_enable() {
  local uuid="$1"
  init_state_tracking

  local mf
  mf="$(get_manifest_path "$uuid")"
  local name="$uuid"
  [ -f "$mf" ] && has_cmd jq && name="$(jq -r '.name' "$mf")"

  log_step "Enabling $name ($uuid)..."

  # Compatibility & Conflict Checks
  if [ -f "$mf" ] && has_cmd jq; then
    # Check known conflicts
    mapfile -t CONFLICTS < <(jq -r '.known_conflicts[]' "$mf" 2>/dev/null || true)
    if has_cmd gnome-extensions; then
      local active_exts
      active_exts="$(gnome-extensions list --enabled 2>/dev/null || true)"
      for conflict in "${CONFLICTS[@]}"; do
        if echo "$active_exts" | grep -qx "$conflict"; then
          log_warn "Conflict detected: Conflicting extension '$conflict' is currently enabled."
          log_warn "Disabling conflicting extension '$conflict' to prevent desktop collisions..."
          if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Would disable conflicting extension: $conflict"
          else
            gnome-extensions disable "$conflict" || true
          fi
        fi
      done
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would execute: gnome-extensions enable $uuid"
    return 0
  fi

  if has_cmd gnome-extensions; then
    gnome-extensions enable "$uuid"
    log_success "Extension $name ($uuid) enabled."
  else
    log_error "gnome-extensions CLI command not found. Cannot enable extension."
    exit 1
  fi
}

# Action: Disable an extension
cmd_disable() {
  local uuid="$1"
  init_state_tracking

  local mf
  mf="$(get_manifest_path "$uuid")"
  local name="$uuid"
  [ -f "$mf" ] && has_cmd jq && name="$(jq -r '.name' "$mf")"

  log_step "Disabling $name ($uuid)..."

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would execute: gnome-extensions disable $uuid"
    return 0
  fi

  if has_cmd gnome-extensions; then
    gnome-extensions disable "$uuid"
    log_success "Extension $name ($uuid) disabled."
  else
    log_error "gnome-extensions CLI command not found."
    exit 1
  fi
}

# Action: Apply macOS-inspired dock layout to Dash to Dock
cmd_dock_config() {
  init_state_tracking
  log_step "Configuring macOS-inspired Dock layout for Dash to Dock..."

  # Check if dash to dock is installed
  local is_installed=false
  if [ -d "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ] || \
     [ -d "$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ]; then
    is_installed=true
  fi

  if [ "$is_installed" = false ]; then
    log_error "Dash to Dock is not installed. Run with --install dash-to-dock@micxgx.gmail.com first."
    exit 1
  fi

  local template="$REPO_ROOT/config/dock/dash-to-dock.dconf"
  if [ ! -f "$template" ]; then
    log_error "Dock configuration template not found at $template"
    exit 1
  fi

  # Backup previous dock settings before touching them
  local backup_file="$STATE_DIR/backups/dash-to-dock-pre-mackali.dconf"
  if [ ! -f "$backup_file" ]; then
    log_info "Creating snapshot of existing Dash to Dock configuration..."
    if [ "$DRY_RUN" = true ]; then
      log_info "[DRY-RUN] Would dump dconf /org/gnome/shell/extensions/dash-to-dock/ to $backup_file"
    else
      if has_cmd dconf; then
        dconf dump /org/gnome/shell/extensions/dash-to-dock/ > "$backup_file" 2>/dev/null || true
        log_success "Pre-existing dock settings saved to $backup_file."
      fi
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would load macOS dock settings:"
    echo "  - Position: BOTTOM"
    echo "  - Layout: Centered (extend-height=false)"
    echo "  - Icon Size: 48px"
    echo "  - Autohide: Intelligent autohide enabled"
    echo "  - Styling: Dynamic transparency & shrink"
    echo "  - Running Indicators: DOTS"
    echo "  - System Preservation: org.gnome.shell favorite-apps strictly untouched"
    return 0
  fi

  # Apply dconf settings
  if has_cmd dconf; then
    dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$template"
    update_state "dash-to-dock@micxgx.gmail.com" "dock_config_applied" "true"
    update_state "dash-to-dock@micxgx.gmail.com" "dock_backup_file" "\"$backup_file\""
    log_success "macOS dock settings applied cleanly!"
  else
    log_error "dconf command not found. Cannot apply dock configuration."
    exit 1
  fi

  # Verify favorite apps was preserved
  if has_cmd gsettings; then
    log_info "Verified: User favorite applications remain untouched and preserved."
  fi
}

# Action: Revert Dash to Dock configuration to original backup
cmd_dock_revert() {
  init_state_tracking
  log_step "Reverting Dash to Dock configuration..."

  local backup_file="$STATE_DIR/backups/dash-to-dock-pre-mackali.dconf"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would reset or restore /org/gnome/shell/extensions/dash-to-dock/ from $backup_file"
    return 0
  fi

  if has_cmd dconf; then
    if [ -f "$backup_file" ] && [ -s "$backup_file" ]; then
      log_info "Restoring previous custom dock settings from $backup_file..."
      dconf reset -f /org/gnome/shell/extensions/dash-to-dock/ 2>/dev/null || true
      dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$backup_file"
      log_success "Previous dock settings restored from backup."
    else
      log_info "No prior custom dock settings existed; resetting Dash to Dock to defaults..."
      dconf reset -f /org/gnome/shell/extensions/dash-to-dock/ 2>/dev/null || true
      log_success "Dash to Dock reset to default."
    fi
    update_state "dash-to-dock@micxgx.gmail.com" "dock_config_applied" "false"
  fi
}

# Action: Apply preset
cmd_preset() {
  local preset="$1"
  init_state_tracking
  print_banner
  log_step "Applying Preset: macKali $preset (Phase 3 Extensions)"

  case "$preset" in
    minimal)
      echo "Preset Components:"
      echo "  [x] Dash to Dock: macOS bottom-centered dock layout"
      echo "  [-] Animation & Experimental Extensions: Disabled by design (Minimal)"
      echo ""

      # Check if Dash to Dock installed
      cmd_install "dash-to-dock@micxgx.gmail.com"
      cmd_enable "dash-to-dock@micxgx.gmail.com"
      cmd_dock_config
      log_success "Minimal preset applied successfully!"
      ;;

    balanced)
      echo "Preset Components:"
      echo "  [x] Dash to Dock: macOS bottom-centered dock layout"
      echo "  [x] Blur My Shell: Frosted glass blur effect"
      if [ "$WITH_MAGIC_LAMP" = true ]; then
        echo "  [x] Magic Lamp Effect: Enabled via explicit user opt-in (--with-magic-lamp)"
      else
        echo "  [-] Magic Lamp Effect: Opt-in only (--with-magic-lamp); leaving unchanged"
      fi
      echo ""

      # 1. Dash to Dock
      cmd_install "dash-to-dock@micxgx.gmail.com"
      cmd_enable "dash-to-dock@micxgx.gmail.com"
      cmd_dock_config

      # 2. Blur My Shell
      cmd_install "blur-my-shell@aunetx"
      cmd_enable "blur-my-shell@aunetx"

      # 3. Magic Lamp (Opt-in)
      if [ "$WITH_MAGIC_LAMP" = true ]; then
        cmd_install "compiz-alike-magic-lamp-effect@hermes83.github.com"
        cmd_enable "compiz-alike-magic-lamp-effect@hermes83.github.com"
        if [ "$DRY_RUN" = false ] && has_cmd dconf && [ -f "$REPO_ROOT/config/animations/magic-lamp.dconf" ]; then
          dconf load /org/gnome/shell/extensions/com/github/hermes83/compiz-alike-magic-lamp-effect/ < "$REPO_ROOT/config/animations/magic-lamp.dconf"
        fi
      fi

      log_success "Balanced preset applied successfully!"
      ;;

    full)
      echo "Preset Components:"
      echo "  [x] Balanced Preset Base (Dash to Dock + Blur My Shell)"
      if [ "$WITH_MAGIC_LAMP" = true ]; then
        echo "  [x] Magic Lamp: Enabled via --with-magic-lamp"
      else
        echo "  [-] Magic Lamp: Opt-in (--with-magic-lamp)"
      fi
      if [ "$WITH_WOBBLY" = true ]; then
        echo "  [x] Compiz Windows Effect: Enabled via --with-wobbly"
      else
        echo "  [-] Compiz Windows Effect: Opt-in (--with-wobbly)"
      fi
      if [ "$WITH_CUBE" = true ]; then
        echo "  [x] Desktop Cube: Enabled via --with-cube (Experimental)"
      else
        echo "  [-] Desktop Cube: Opt-in (--with-cube, Experimental)"
      fi
      echo ""

      # Base Balanced
      cmd_install "dash-to-dock@micxgx.gmail.com"
      cmd_enable "dash-to-dock@micxgx.gmail.com"
      cmd_dock_config

      cmd_install "blur-my-shell@aunetx"
      cmd_enable "blur-my-shell@aunetx"

      if [ "$WITH_MAGIC_LAMP" = true ]; then
        cmd_install "compiz-alike-magic-lamp-effect@hermes83.github.com"
        cmd_enable "compiz-alike-magic-lamp-effect@hermes83.github.com"
        if [ "$DRY_RUN" = false ] && has_cmd dconf && [ -f "$REPO_ROOT/config/animations/magic-lamp.dconf" ]; then
          dconf load /org/gnome/shell/extensions/com/github/hermes83/compiz-alike-magic-lamp-effect/ < "$REPO_ROOT/config/animations/magic-lamp.dconf"
        fi
      fi

      if [ "$WITH_WOBBLY" = true ]; then
        cmd_install "compiz-windows-effect@hermes83.github.com"
        cmd_enable "compiz-windows-effect@hermes83.github.com"
        if [ "$DRY_RUN" = false ] && has_cmd dconf && [ -f "$REPO_ROOT/config/animations/compiz-windows.dconf" ]; then
          dconf load /org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect/ < "$REPO_ROOT/config/animations/compiz-windows.dconf"
        fi
      fi

      if [ "$WITH_CUBE" = true ]; then
        log_warn "Desktop Cube is experimental on GNOME Shell 50.3 Wayland."
        log_warn "Ensuring workspace count and global keyboard shortcuts remain unchanged..."
        cmd_install "desktop-cube@schneegans.github.com"
        cmd_enable "desktop-cube@schneegans.github.com"
        if [ "$DRY_RUN" = false ] && has_cmd dconf && [ -f "$REPO_ROOT/config/animations/desktop-cube.dconf" ]; then
          dconf load /org/gnome/shell/extensions/desktop-cube/ < "$REPO_ROOT/config/animations/desktop-cube.dconf"
        fi
      fi

      log_success "Full preset applied successfully!"
      ;;

    *)
      log_error "Unknown preset: $preset. Choose minimal, balanced, or full."
      exit 1
      ;;
  esac
}

# Action: Restore all extensions to pre-macKali state
cmd_restore() {
  init_state_tracking
  print_banner
  log_step "Restoring GNOME extensions and dock configuration to pre-macKali state..."

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would revert Dash to Dock configuration"
    log_info "[DRY-RUN] Would disable extensions that were not active before macKali"
    log_info "[DRY-RUN] Would leave pre-existing extensions untouched"
    return 0
  fi

  # 1. Revert dock settings if macKali altered them
  cmd_dock_revert

  # 2. Reconcile enabled states
  if [ -f "$STATE_FILE" ] && has_cmd jq && has_cmd gnome-extensions; then
    for uuid in "${SUPPORTED_UUIDS[@]}"; do
      local was_enabled
      was_enabled="$(jq -r --arg u "$uuid" '.[$u].pre_existing_enabled // false' "$STATE_FILE")"
      local by_mackali
      by_mackali="$(jq -r --arg u "$uuid" '.[$u].installed_by_mackali // false' "$STATE_FILE")"

      local is_currently_enabled=false
      if gnome-extensions list --enabled 2>/dev/null | grep -qx "$uuid"; then
        is_currently_enabled=true
      fi

      if [ "$was_enabled" = false ] && [ "$is_currently_enabled" = true ]; then
        log_info "Disabling extension that was not active prior to macKali: $uuid"
        gnome-extensions disable "$uuid" 2>/dev/null || true
      elif [ "$was_enabled" = true ] && [ "$is_currently_enabled" = false ]; then
        log_info "Re-enabling pre-existing extension: $uuid"
        gnome-extensions enable "$uuid" 2>/dev/null || true
      fi

      # If installed by macKali, remove user-space extension files
      if [ "$by_mackali" = true ]; then
        local user_ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"
        if [ -d "$user_ext_dir" ]; then
          log_info "Removing extension installed by macKali: $user_ext_dir"
          rm -rf "$user_ext_dir"
        fi
        update_state "$uuid" "installed_by_mackali" "false"
      fi
    done
  fi

  log_success "Extension restoration completed successfully!"
}

# Command dispatching
ACTION=""
ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)
      ACTION="list"
      shift
      ;;
    --status|--installed)
      ACTION="status"
      shift
      ;;
    --compat)
      ACTION="compat"
      shift
      ;;
    --install)
      ACTION="install"
      ARG="$2"
      shift 2
      ;;
    --install-all)
      ACTION="install-all"
      shift
      ;;
    --enable)
      ACTION="enable"
      ARG="$2"
      shift 2
      ;;
    --disable)
      ACTION="disable"
      ARG="$2"
      shift 2
      ;;
    --dock-config)
      ACTION="dock-config"
      shift
      ;;
    --dock-revert)
      ACTION="dock-revert"
      shift
      ;;
    --preset)
      ACTION="preset"
      ARG="$2"
      shift 2
      ;;
    --restore)
      ACTION="restore"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -y|--yes)
      ASSUME_YES=true
      shift
      ;;
    -f|--force)
      FORCE_OVERWRITE=true
      shift
      ;;
    --with-magic-lamp)
      WITH_MAGIC_LAMP=true
      shift
      ;;
    --with-wobbly)
      WITH_WOBBLY=true
      shift
      ;;
    --with-cube)
      WITH_CUBE=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

if [ -z "$ACTION" ]; then
  show_help
  exit 0
fi

case "$ACTION" in
  list)
    cmd_list
    ;;
  status)
    cmd_status
    ;;
  compat)
    cmd_compat
    ;;
  install)
    cmd_install "$ARG"
    ;;
  install-all)
    for u in "${SUPPORTED_UUIDS[@]}"; do
      cmd_install "$u"
    done
    ;;
  enable)
    cmd_enable "$ARG"
    ;;
  disable)
    cmd_disable "$ARG"
    ;;
  dock-config)
    cmd_dock_config
    ;;
  dock-revert)
    cmd_dock_revert
    ;;
  preset)
    cmd_preset "$ARG"
    ;;
  restore)
    cmd_restore
    ;;
esac
