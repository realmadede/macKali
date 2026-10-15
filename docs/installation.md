# macKali Installation Guide

This document covers both the **Automated** and **Manual** workflows for deploying macKali desktop components on Kali Linux.

---

## Prerequisites

- **Operating System**: Kali Linux Rolling (or Debian/Ubuntu-based GNOME desktop)
- **Desktop Environment**: GNOME Shell 45 through 51
- **Recommended Packages**:
  ```bash
  sudo apt install -y dconf-cli gnome-tweaks git python3
  ```
  If building cursors from source:
  ```bash
  sudo apt install -y xorg-xcursorgen librsvg2-bin
  ```

---

## Workflow 1: Automated Installation

The automated installer is driven by `scripts/install.sh` (or the top-level `./install.sh` wrapper).

### Step 1: Run Compatibility Check
Verify that your OS version, GNOME Shell release, and system utilities meet requirements:

```bash
./scripts/compat-check.sh
# or
./install.sh --check
```

### Step 2: Choose an Installation Preset

| Preset | Target Experience | Included Components (Phase 1) |
| :--- | :--- | :--- |
| `minimal` | Lightweight macOS layout | WhiteSur cursors, dock config schema, window buttons on left |
| `balanced` | Authentic macOS polish | Minimal + Blur My Shell schema + Magic Lamp schema |
| `full` | macOS + 3D Compiz effects | Balanced + Desktop Cube schema + Wobbly Windows schema |

### Step 3: Run the Installer

To run with a safety backup and the recommended `balanced` preset:

```bash
./scripts/install.sh --preset balanced --backup
```

To preview changes without touching files or settings:

```bash
./scripts/install.sh --preset balanced --dry-run
```

To install only the cursors:

```bash
./install.sh
# or
./scripts/install.sh --cursors-only
```

---

## Workflow 2: Manual Installation

If you prefer to inspect and apply components individually without automation scripts:

### 1. Install WhiteSur Cursors
Copy precompiled cursor binaries to your local icons directory:

```bash
mkdir -p ~/.local/share/icons/WhiteSur-cursors
cp -pr themes/cursors/dist/* ~/.local/share/icons/WhiteSur-cursors/
```

Activate the cursor theme:
```bash
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
gsettings set org.gnome.desktop.interface cursor-size 24
```

### 2. Configure Window Controls (macOS Left Traffic Lights)
Move window close, minimize, and maximize buttons to the top-left:

```bash
dconf load / < config/gnome/01-wm-preferences.dconf
# Alternatively via gsettings:
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
```

### 3. Configure Dock Appearance (Requires Dash to Dock)
If you have installed Dash to Dock, apply the bottom-centered macOS dock configuration:

```bash
dconf load / < config/dock/dash-to-dock.dconf
```

### 4. Configure Animations & Keybindings
```bash
# Magic lamp genie effect:
dconf load / < config/animations/magic-lamp.dconf

# macOS keyboard shortcuts:
dconf load / < config/keybindings/custom-shortcuts.dconf
```

---

## Uninstallation & Rollback

### Restore from Backup
To rollback all GNOME settings to your pre-install state:

```bash
./scripts/restore.sh
```

### Clean Removal of Cursors
```bash
./scripts/uninstall.sh
```
