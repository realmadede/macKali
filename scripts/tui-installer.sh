#!/usr/bin/env bash
# macKali Interactive Terminal UI (TUI) Installer
# Phase 4A: Guided terminal customization wizard with whiptail/dialog and plain-terminal fallback.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

MACKALI_VERSION="0.4.0-dev"
if has_cmd git && [ -d "$REPO_ROOT/.git" ]; then
  GIT_VER="$(git -C "$REPO_ROOT" describe --tags --always 2>/dev/null || true)"
  [ -n "$GIT_VER" ] && MACKALI_VERSION="$GIT_VER"
fi

# Options & defaults
DRY_RUN=false
NON_INTERACTIVE=false
FORCE_BACKEND=""
PRESELECTED_PRESET=""
PRESELECTED_MODE=""
DO_BACKUP=true

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plain|--text)
      FORCE_BACKEND="plain"
      shift
      ;;
    --whiptail)
      FORCE_BACKEND="whiptail"
      shift
      ;;
    --dialog)
      FORCE_BACKEND="dialog"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    --preset)
      PRESELECTED_PRESET="$2"
      shift 2
      ;;
    --mode)
      PRESELECTED_MODE="$2"
      shift 2
      ;;
    --no-backup)
      DO_BACKUP=false
      shift
      ;;
    --help|-h)
      echo "macKali Interactive Terminal (TUI) Installer"
      echo "==========================================="
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --plain, --text      Force plain-terminal text mode (no whiptail/dialog)"
      echo "  --whiptail           Force whiptail dialog backend"
      echo "  --dialog             Force dialog backend"
      echo "  --dry-run            Simulate installation without modifying desktop settings"
      echo "  --non-interactive    Run without interactive prompts (uses defaults/flags)"
      echo "  --preset NAME        Pre-select preset (minimal, balanced, full)"
      echo "  --mode MODE          Pre-select appearance mode (dark, light)"
      echo "  --no-backup          Disable automatic desktop settings backup"
      echo "  -h, --help           Show this help message"
      echo ""
      echo "Entry points:"
      echo "  ./install.sh --interactive"
      echo "  ./scripts/install.sh --interactive"
      echo "  ./scripts/tui-installer.sh"
      exit 0
      ;;
    *)
      log_error "Unknown option: $1. Run with --help for usage."
      exit 1
      ;;
  esac
done

# Backend Detection
detect_backend() {
  local requested=""
  [ -n "$FORCE_BACKEND" ] && requested="$FORCE_BACKEND"
  [ -z "$requested" ] && [ -n "$TUI_BACKEND" ] && requested="$TUI_BACKEND"

  if [ -n "$requested" ]; then
    case "$requested" in
      whiptail)
        if has_cmd whiptail; then
          UI_BACKEND="whiptail"
          return 0
        else
          log_warn "whiptail is not installed. Falling back to plain-terminal mode."
          UI_BACKEND="plain"
          return 0
        fi
        ;;
      dialog)
        if has_cmd dialog; then
          UI_BACKEND="dialog"
          return 0
        else
          log_warn "dialog is not installed. Falling back to plain-terminal mode."
          UI_BACKEND="plain"
          return 0
        fi
        ;;
      plain|text)
        UI_BACKEND="plain"
        return 0
        ;;
      *)
        log_warn "Unknown UI backend '$requested'. Falling back to plain-terminal mode."
        UI_BACKEND="plain"
        return 0
        ;;
    esac
  fi

  # Auto-detect best available interactive backend
  if [ -t 0 ] && [ -t 1 ]; then
    if has_cmd whiptail; then
      UI_BACKEND="whiptail"
    elif has_cmd dialog; then
      UI_BACKEND="dialog"
    else
      UI_BACKEND="plain"
    fi
  else
    UI_BACKEND="plain"
  fi
}

detect_backend

# -------------------------------------------------------------
# UI Primitive Helpers (Whiptail / Dialog / Plain Fallback)
# -------------------------------------------------------------

ui_msgbox() {
  local title="$1"
  local text="$2"

  if [ "$UI_BACKEND" = "whiptail" ]; then
    whiptail --title "$title" --msgbox "$text" 20 76
  elif [ "$UI_BACKEND" = "dialog" ]; then
    dialog --title "$title" --msgbox "$text" 20 76
  else
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}=== $title ===${COLOR_RESET}" >&2
    echo -e "$text" >&2
    echo "" >&2
    if [ "$NON_INTERACTIVE" != true ] && [ -t 0 ]; then
      read -r -p "Press [Enter] to continue..." || true
    fi
  fi
}

ui_yesno() {
  local title="$1"
  local text="$2"
  local default_yes="${3:-true}"

  if [ "$UI_BACKEND" = "whiptail" ]; then
    if [ "$default_yes" = true ]; then
      whiptail --title "$title" --yesno "$text" 16 76
    else
      whiptail --title "$title" --defaultno --yesno "$text" 16 76
    fi
  elif [ "$UI_BACKEND" = "dialog" ]; then
    if [ "$default_yes" = true ]; then
      dialog --title "$title" --yesno "$text" 16 76
    else
      dialog --title "$title" --defaultno --yesno "$text" 16 76
    fi
  else
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}=== $title ===${COLOR_RESET}" >&2
    echo -e "$text" >&2
    local prompt_hint="[Y/n]"
    [ "$default_yes" = false ] && prompt_hint="[y/N]"

    if [ "$NON_INTERACTIVE" = true ]; then
      [ "$default_yes" = true ] && return 0 || return 1
    fi

    local ans=""
    read -r -p "Choice $prompt_hint: " ans || ans=""
    ans="$(echo "$ans" | tr '[:upper:]' '[:lower:]')"
    if [ -z "$ans" ]; then
      [ "$default_yes" = true ] && return 0 || return 1
    fi
    if [[ "$ans" =~ ^(y|yes)$ ]]; then
      return 0
    else
      return 1
    fi
  fi
}

ui_menu() {
  local title="$1"
  local text="$2"
  local default_item="$3"
  shift 3
  local options=("$@")

  if [ "$UI_BACKEND" = "whiptail" ]; then
    local choice
    choice=$(whiptail --title "$title" --default-item "$default_item" --menu "$text" 20 76 6 "${options[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "$choice"
  elif [ "$UI_BACKEND" = "dialog" ]; then
    local choice
    choice=$(dialog --title "$title" --default-item "$default_item" --menu "$text" 20 76 6 "${options[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "$choice"
  else
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}=== $title ===${COLOR_RESET}" >&2
    echo -e "$text\n" >&2

    local idx=1
    declare -A num_to_tag
    local default_num=1

    for ((i=0; i<${#options[@]}; i+=2)); do
      local tag="${options[i]}"
      local desc="${options[i+1]}"
      num_to_tag[$idx]="$tag"
      if [ "$tag" = "$default_item" ]; then
        default_num=$idx
        echo -e "  ${COLOR_BOLD}$idx)${COLOR_RESET} ${COLOR_GREEN}$tag${COLOR_RESET} (Default) - $desc" >&2
      else
        echo -e "  ${COLOR_BOLD}$idx)${COLOR_RESET} $tag - $desc" >&2
      fi
      idx=$((idx + 1))
    done

    if [ "$NON_INTERACTIVE" = true ]; then
      echo "$default_item"
      return 0
    fi

    local max_num=$((idx - 1))
    local sel=""
    read -r -p "Enter selection [1-$max_num, default: $default_num] (or 'q' to cancel): " sel || sel=""
    if [[ "$sel" =~ ^(q|quit|cancel)$ ]]; then
      return 1
    fi
    if [ -z "$sel" ]; then
      echo "${num_to_tag[$default_num]}"
      return 0
    fi
    if [ -n "${num_to_tag[$sel]}" ]; then
      echo "${num_to_tag[$sel]}"
      return 0
    fi

    # Fallback to direct tag match if user typed tag name
    for ((i=0; i<${#options[@]}; i+=2)); do
      if [ "${options[i]}" = "$sel" ]; then
        echo "$sel"
        return 0
      fi
    done

    echo "${num_to_tag[$default_num]}"
  fi
}

ui_radiolist() {
  local title="$1"
  local text="$2"
  local default_item="$3"
  shift 3
  local options=("$@")

  if [ "$UI_BACKEND" = "whiptail" ]; then
    local choice
    choice=$(whiptail --title "$title" --radiolist "$text" 16 76 4 "${options[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "$choice"
  elif [ "$UI_BACKEND" = "dialog" ]; then
    local choice
    choice=$(dialog --title "$title" --radiolist "$text" 16 76 4 "${options[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "$choice"
  else
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}=== $title ===${COLOR_RESET}" >&2
    echo -e "$text\n" >&2

    local idx=1
    declare -A num_to_tag
    local default_num=1

    for ((i=0; i<${#options[@]}; i+=3)); do
      local tag="${options[i]}"
      local desc="${options[i+1]}"
      local status="${options[i+2]}"
      num_to_tag[$idx]="$tag"
      if [ "$status" = "ON" ] || [ "$tag" = "$default_item" ]; then
        default_num=$idx
        echo -e "  ${COLOR_BOLD}$idx)${COLOR_RESET} ${COLOR_GREEN}$tag${COLOR_RESET} (Default) - $desc" >&2
      else
        echo -e "  ${COLOR_BOLD}$idx)${COLOR_RESET} $tag - $desc" >&2
      fi
      idx=$((idx + 1))
    done

    if [ "$NON_INTERACTIVE" = true ]; then
      echo "$default_item"
      return 0
    fi

    local max_num=$((idx - 1))
    local sel=""
    read -r -p "Enter selection [1-$max_num, default: $default_num] (or 'q' to cancel): " sel || sel=""
    if [[ "$sel" =~ ^(q|quit|cancel)$ ]]; then
      return 1
    fi
    if [ -z "$sel" ]; then
      echo "${num_to_tag[$default_num]}"
      return 0
    fi
    if [ -n "${num_to_tag[$sel]}" ]; then
      echo "${num_to_tag[$sel]}"
      return 0
    fi

    echo "${num_to_tag[$default_num]}"
  fi
}

# -------------------------------------------------------------
# Step A: Welcome & Environment Inspection
# -------------------------------------------------------------
step_welcome() {
  detect_os
  detect_de
  detect_gnome_version
  detect_session_type

  local prereq_text="OK"
  local warnings=""

  if ! has_cmd gnome-shell; then
    warnings+="\n- [WARN] gnome-shell is not detected. Extension features require GNOME Shell."
    prereq_text="Incomplete (Non-GNOME Environment)"
  fi

  if ! has_cmd gsettings; then
    warnings+="\n- [WARN] gsettings is missing. Appearance settings cannot be configured automatically."
    prereq_text="Incomplete (Missing gsettings)"
  fi

  if ! has_cmd dconf; then
    warnings+="\n- [WARN] dconf is missing. Backup and dock configuration will be limited."
    prereq_text="Incomplete (Missing dconf)"
  fi

  local welcome_msg
  welcome_msg="Welcome to the macKali Desktop Customization Wizard!

Version:     $MACKALI_VERSION
OS:          $OS_NAME (Version: $OS_VERSION)
Desktop:     $DE_NAME
Session:     $SESSION_TYPE
GNOME Shell: $GNOME_VERSION (Major: $GNOME_MAJOR_VERSION)
UI Backend:  $UI_BACKEND
Prereqs:     $prereq_text$warnings

macKali transforms your desktop into an authentic macOS experience
while strictly preserving Kali security launchers, favorite apps,
and system stability."

  if [ -n "$warnings" ]; then
    welcome_msg+="\n\nNote: You can proceed, but features requiring missing tools will be safely skipped."
  fi

  if ! ui_yesno "macKali Setup Wizard" "$welcome_msg\n\nWould you like to continue?" true; then
    log_info "Setup wizard cancelled by user. No modifications were made."
    exit 0
  fi
}

# -------------------------------------------------------------
# Step B: Preset Selection
# -------------------------------------------------------------
step_select_preset() {
  if [ -n "$PRESELECTED_PRESET" ]; then
    SELECTED_PRESET="$PRESELECTED_PRESET"
    return 0
  fi

  local presets_dir="$REPO_ROOT/extensions/presets"
  local min_desc="Lightweight macOS look (Cursors, left buttons, centered dock)"
  local bal_desc="Modern macOS experience (Cursors, dock, frosted glass blur)"
  local full_desc="Full visual flair (Balanced + Compiz wobbly windows & 3D cube)"

  if [ -f "$presets_dir/minimal.json" ] && has_cmd jq; then
    min_desc="$(jq -r '.description' "$presets_dir/minimal.json" 2>/dev/null | cut -c1-65)..."
  fi
  if [ -f "$presets_dir/balanced.json" ] && has_cmd jq; then
    bal_desc="$(jq -r '.description' "$presets_dir/balanced.json" 2>/dev/null | cut -c1-65)..."
  fi
  if [ -f "$presets_dir/full.json" ] && has_cmd jq; then
    full_desc="$(jq -r '.description' "$presets_dir/full.json" 2>/dev/null | cut -c1-65)..."
  fi

  local menu_options=(
    "balanced" "Balanced (Recommended) - $bal_desc"
    "minimal"  "Minimal - $min_desc"
    "full"     "Full (Nostalgia & 3D) - $full_desc"
  )

  local choice
  choice=$(ui_menu "Installation Preset" "Choose an installation preset tier:" "balanced" "${menu_options[@]}") || {
    log_info "Setup wizard cancelled during preset selection."
    exit 0
  }

  SELECTED_PRESET="$choice"
}

# -------------------------------------------------------------
# Step C: Customization Options & Compatibility Evaluation
# -------------------------------------------------------------
step_customization_and_compatibility() {
  local mf_dir="$REPO_ROOT/extensions/manifests"

  # Evaluate compatibility across all 5 target extensions
  evaluate_extension_compat "dash-to-dock@micxgx.gmail.com" "$mf_dir/dash-to-dock.json" "$GNOME_MAJOR_VERSION" false
  COMPAT_DOCK="$COMPAT_STATUS"

  evaluate_extension_compat "blur-my-shell@aunetx" "$mf_dir/blur-my-shell.json" "$GNOME_MAJOR_VERSION" false
  COMPAT_BLUR="$COMPAT_STATUS"

  evaluate_extension_compat "compiz-alike-magic-lamp-effect@hermes83.github.com" "$mf_dir/compiz-alike-magic-lamp-effect.json" "$GNOME_MAJOR_VERSION" false
  COMPAT_MAGIC="$COMPAT_STATUS"

  evaluate_extension_compat "compiz-windows-effect@hermes83.github.com" "$mf_dir/compiz-windows-effect.json" "$GNOME_MAJOR_VERSION" false
  COMPAT_WOBBLY="$COMPAT_STATUS"

  evaluate_extension_compat "desktop-cube@schneegans.github.com" "$mf_dir/desktop-cube.json" "$GNOME_MAJOR_VERSION" false
  COMPAT_CUBE="$COMPAT_STATUS"

  # 1. Appearance Color Scheme
  if [ -n "$PRESELECTED_MODE" ]; then
    SELECTED_MODE="$PRESELECTED_MODE"
  else
    local mode_options=(
      "dark"  "macOS Dark Mode (Native dark window controls & dark wallpaper)" "ON"
      "light" "macOS Light Mode (Native light window controls & light wallpaper)" "OFF"
    )
    SELECTED_MODE=$(ui_radiolist "Appearance Theme" "Select your preferred macOS appearance theme:" "dark" "${mode_options[@]}") || {
      log_info "Setup wizard cancelled during theme selection."
      exit 0
    }
  fi

  # 2. Component Toggles
  DO_CURSORS=true
  DO_APPEARANCE=true
  DO_WALLPAPERS=true
  DO_EXTENSIONS=true
  OPT_MAGIC_LAMP=false
  OPT_WOBBLY=false
  OPT_CUBE=false

  # In plain text mode or interactive mode, confirm components cleanly
  if [ "$UI_BACKEND" = "whiptail" ] || [ "$UI_BACKEND" = "dialog" ]; then
    local check_items=(
      "CURSORS"     "WhiteSur macOS Cursor Theme" "ON"
      "APPEARANCE"  "macOS Left Window Controls & GTK Theme" "ON"
      "WALLPAPERS"  "macOS Bundled 4K Light & Dark Wallpapers" "ON"
      "DOCK_EXT"    "Dash to Dock macOS Bottom Layout" "ON"
    )

    if [ "$SELECTED_PRESET" = "balanced" ] || [ "$SELECTED_PRESET" = "full" ]; then
      if [ "$COMPAT_MAGIC" != "UNSUPPORTED" ]; then
        check_items+=("MAGIC_LAMP" "Genie Lamp Animation (Optional Opt-in)" "OFF")
      fi
    fi

    if [ "$SELECTED_PRESET" = "full" ]; then
      if [ "$COMPAT_WOBBLY" != "UNSUPPORTED" ]; then
        check_items+=("WOBBLY" "Compiz Wobbly Windows (Optional Opt-in)" "OFF")
      fi
      if [ "$COMPAT_CUBE" != "UNSUPPORTED" ]; then
        check_items+=("CUBE" "Desktop Workspace 3D Cube (Experimental Opt-in)" "OFF")
      fi
    fi

    local selected_boxes
    if [ "$UI_BACKEND" = "whiptail" ]; then
      selected_boxes=$(whiptail --title "Customize Components" --checklist "Toggle customization components to install:" 22 76 7 "${check_items[@]}" 3>&1 1>&2 2>&3) || {
        log_info "Setup wizard cancelled during component selection."
        exit 0
      }
    else
      selected_boxes=$(dialog --title "Customize Components" --checklist "Toggle customization components to install:" 22 76 7 "${check_items[@]}" 3>&1 1>&2 2>&3) || {
        log_info "Setup wizard cancelled during component selection."
        exit 0
      }
    fi

    DO_CURSORS=false
    DO_APPEARANCE=false
    DO_WALLPAPERS=false
    DO_EXTENSIONS=false
    OPT_MAGIC_LAMP=false
    OPT_WOBBLY=false
    OPT_CUBE=false

    echo "$selected_boxes" | grep -q "CURSORS" && DO_CURSORS=true
    echo "$selected_boxes" | grep -q "APPEARANCE" && DO_APPEARANCE=true
    echo "$selected_boxes" | grep -q "WALLPAPERS" && DO_WALLPAPERS=true
    echo "$selected_boxes" | grep -q "DOCK_EXT" && DO_EXTENSIONS=true
    echo "$selected_boxes" | grep -q "MAGIC_LAMP" && OPT_MAGIC_LAMP=true
    echo "$selected_boxes" | grep -q "WOBBLY" && OPT_WOBBLY=true
    echo "$selected_boxes" | grep -q "CUBE" && OPT_CUBE=true
  else
    # Plain text mode defaults to preset recommended components
    if [ "$SELECTED_PRESET" = "full" ]; then
      if [ "$NON_INTERACTIVE" != true ] && [ -t 0 ]; then
        ui_yesno "Experimental Effects" "Enable Compiz Wobbly Windows effect? (--with-wobbly)" false && OPT_WOBBLY=true || true
        ui_yesno "Experimental Effects" "Enable Desktop 3D Workspace Cube? (--with-cube, experimental)" false && OPT_CUBE=true || true
        ui_yesno "Animation Effects" "Enable Genie Magic Lamp minimize animation? (--with-magic-lamp)" false && OPT_MAGIC_LAMP=true || true
      fi
    elif [ "$SELECTED_PRESET" = "balanced" ]; then
      if [ "$NON_INTERACTIVE" != true ] && [ -t 0 ]; then
        ui_yesno "Animation Effects" "Enable Genie Magic Lamp minimize animation? (--with-magic-lamp)" false && OPT_MAGIC_LAMP=true || true
      fi
    fi
  fi
}

# -------------------------------------------------------------
# Step D: Compatibility & Safety Review
# -------------------------------------------------------------
step_safety_review() {
  local compat_text="Universal Components (Independent of GNOME version):
  - [OK] Wallpapers:          Native GNOME picture-uri pairing
  - [OK] Cursor Theme:        Freedesktop XDG standard (Wayland & X11)
  - [OK] Appearance & GTK:    Native libadwaita/GTK4 color negotiation

Shell & Extension Components Status (Target: GNOME $GNOME_MAJOR_VERSION):
  - Dash to Dock:             $COMPAT_DOCK
  - Blur My Shell:            $COMPAT_BLUR
  - Magic Lamp Effect:        $COMPAT_MAGIC
  - Compiz Windows Effect:    $COMPAT_WOBBLY
  - Desktop Workspace Cube:   $COMPAT_CUBE

macKali Safety Guarantees:
  - Your favorite applications and Kali security tools are preserved.
  - GNOME native extension validation is strictly maintained.
  - No system APT repositories or packages are modified.
  - Single-command restoration is available at any time."

  ui_msgbox "Compatibility & System Safety" "$compat_text"
}

# -------------------------------------------------------------
# Step E: Backup and Confirmation
# -------------------------------------------------------------
step_confirmation() {
  # Backup Prompt
  if [ "$DO_BACKUP" = true ]; then
    if ! ui_yesno "Desktop Safety Backup" "Create an automatic timestamped backup of your current GNOME settings before applying changes? (Highly Recommended)" true; then
      DO_BACKUP=false
    fi
  fi

  local exec_mode="Live Desktop Customization"
  [ "$DRY_RUN" = true ] && exec_mode="Dry-Run Simulation (No system changes will be made)"

  local ext_summary="None"
  if [ "$DO_EXTENSIONS" = true ]; then
    ext_summary="Dash to Dock layout"
    [ "$SELECTED_PRESET" != "minimal" ] && ext_summary+=", Blur My Shell"
    [ "$OPT_MAGIC_LAMP" = true ] && ext_summary+=", Magic Lamp"
    [ "$OPT_WOBBLY" = true ] && ext_summary+=", Wobbly Windows"
    [ "$OPT_CUBE" = true ] && ext_summary+=", Desktop Cube"
  fi

  local summary_msg="Please review your macKali installation plan:

Preset Tier:       $SELECTED_PRESET
Execution Mode:    $exec_mode
Theme Mode:        $SELECTED_MODE
WhiteSur Cursors:  $( [ "$DO_CURSORS" = true ] && echo "Yes" || echo "No" )
Window Controls:   $( [ "$DO_APPEARANCE" = true ] && echo "Left Traffic Lights" || echo "No" )
4K Wallpapers:     $( [ "$DO_WALLPAPERS" = true ] && echo "Yes" || echo "No" )
Dock & Extensions: $ext_summary
Safety Backup:     $( [ "$DO_BACKUP" = true ] && echo "Yes" || echo "No" )

Do you wish to proceed with applying these customizations?"

  if ! ui_yesno "Confirm Customization" "$summary_msg" true; then
    log_info "macKali installation cancelled by user. No modifications were made."
    exit 0
  fi
}

# -------------------------------------------------------------
# Step F: Execution & Results Reporting
# -------------------------------------------------------------
step_execute_and_report() {
  log_step "Applying macKali Desktop Customization..."

  local install_cmd=("$REPO_ROOT/scripts/install.sh" "--preset" "$SELECTED_PRESET")

  [ "$DO_BACKUP" = true ] && install_cmd+=("--backup")
  [ "$DO_APPEARANCE" = true ] && install_cmd+=("--appearance" "--mode" "$SELECTED_MODE")
  [ "$DO_WALLPAPERS" = true ] && install_cmd+=("--wallpaper")
  [ "$DO_EXTENSIONS" = true ] && install_cmd+=("--extensions")
  [ "$OPT_MAGIC_LAMP" = true ] && install_cmd+=("--with-magic-lamp")
  [ "$OPT_WOBBLY" = true ] && install_cmd+=("--with-wobbly")
  [ "$OPT_CUBE" = true ] && install_cmd+=("--with-cube")
  [ "$DRY_RUN" = true ] && install_cmd+=("--dry-run")

  # Run the established installer engine
  local exit_code=0
  "${install_cmd[@]}" || exit_code=$?

  if [ $exit_code -eq 0 ]; then
    local final_msg="macKali Customization Completed Successfully!

Applied Components:
  - WhiteSur Cursor Theme: Installed to ~/.local/share/icons
  - Appearance Settings:  macOS $SELECTED_MODE mode with left window controls
  - 4K Wallpapers:         macOS Light & Dark paired wallpapers
  - Dock & Extensions:     macOS centered dock & compatible extensions

Recovery & Reversion Instructions:
  - Revert all settings anytime:      ./scripts/restore.sh
  - Revert dock styling only:          ./scripts/extensions-manager.sh --dock-revert
  - Revert appearance styling only:    ./scripts/appearance.sh --revert
  - Completely remove macKali:        ./scripts/uninstall.sh --purge
  - Virtual Console (TTY) Emergency:   Ctrl + Alt + F3, then:
    ./scripts/extensions-manager.sh --restore"

    ui_msgbox "Installation Complete" "$final_msg"
  else
    local err_msg="One or more components encountered an issue during installation.

The established safety engine prevented destructive changes.
Universal components (cursors, themes, wallpapers) remain safe.

To restore previous settings, run:
  ./scripts/restore.sh"

    ui_msgbox "Installation Warning" "$err_msg"
    return $exit_code
  fi
}

# Main Execution Flow
main() {
  check_not_root
  step_welcome
  step_select_preset
  step_customization_and_compatibility
  step_safety_review
  step_confirmation
  step_execute_and_report
}

main "$@"
