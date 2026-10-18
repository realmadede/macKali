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

## Try Before You Install (Pre-Flight & Dry-Run Mode)

Want to evaluate macKali without modifying your desktop first? Every installer workflow supports read-only inspection and simulation flags that make **zero changes** to your files or GNOME settings:

```bash
# 1. Check GNOME compatibility and session readiness (0 changes):
./install.sh --check

# 2. Simulate the interactive wizard or full preset in Dry-Run mode (0 changes):
./install.sh --interactive --dry-run
./install.sh --dry-run --full

# 3. Preview circular traffic-light CSS and window button rules only (0 changes):
./scripts/appearance.sh --preview
```

> [!TIP]
> Because macKali is 100% rootless and user-scoped (`~/.config` and `~/.local/share`), you can also test a live installation inside a **secondary Linux user account** or a **Virtual Machine snapshot** without touching your main desktop. See [How to Test macKali Safely Before Installing](safety-and-removal.md#3-how-to-test-mackali-safely-before-installing-zero-risk-evaluation) for the full 4-tier guide.

---

## Workflow 1: Verified Release Archive (Recommended for Users)

For production deployments, download the standalone macKali distribution archive and verify its cryptographic integrity using the official `SHA256SUMS` manifest before extracting:

### Step 1: Download Release Archive & Checksums
Download the latest release candidate assets from GitHub:

```bash
VERSION="1.0.0-rc.1"
curl -sLO "https://github.com/realmadede/macKali/releases/download/v${VERSION}/macKali-v${VERSION}.tar.gz"
curl -sLO "https://github.com/realmadede/macKali/releases/download/v${VERSION}/SHA256SUMS"
```

### Step 2: Verify Archive Integrity (SHA-256)
Validate that the downloaded file matches the official checksum manifest:

```bash
sha256sum -c SHA256SUMS
```
Expected output:
```text
macKali-v1.0.0-rc.1.tar.gz: OK
```

> [!IMPORTANT]
> **Integrity vs Identity**: Checksum verification proves the downloaded archive was transmitted without data corruption or tampering relative to the published manifest. It does not cryptographically prove publisher identity. Always ensure you download both archive and checksums directly from the official GitHub repository at `https://github.com/realmadede/macKali/releases`.

### Step 3: Extract and Launch the Interactive Wizard
```bash
tar -xzf "macKali-v${VERSION}.tar.gz"
cd "macKali-v${VERSION}"
./install.sh --interactive
```
The extracted package is completely self-contained and operates independently of any Git repository.

---

## Workflow 2: Interactive Terminal Wizard (Git Clone)

macKali includes a dedicated interactive terminal customization wizard (`scripts/tui-installer.sh`) designed to make installation effortless, safe, and transparent:

```bash
./install.sh --interactive
# or
./scripts/install.sh -i
```

### Key Wizard Capabilities
- **Adaptive UI Backends**: Seamlessly uses `whiptail` or `dialog` for high-quality dialog boxes if available, and gracefully falls back to an ANSI plain-terminal interface if neither is installed.
- **Environment Detection**: Detects your Linux distribution, desktop environment, GNOME Shell version, and session type (Wayland or X11) at startup.
- **Dynamic 4-Tier Compatibility Check**: Evaluates GNOME extensions dynamically against your running GNOME Shell version without artificial version limits.
- **Guided Preset Selection**: Choose from `minimal`, `balanced` (recommended), or `full` presets with clear, dynamic descriptions read directly from preset manifests.
- **Granular Customization**: Toggle Dark/Light color schemes, WhiteSur cursors, 4K wallpapers, extensions, and optional 3D effects (Magic Lamp, Compiz Windows, Desktop Cube).
- **Default Safety Backups**: Automatically enables timestamped `dconf` configuration backups before any changes are made.
- **Dry-Run & Clean Cancellation**: Test the entire flow with `--dry-run`, or cancel at any step before execution to exit with zero system changes.
- **Instant Recovery Summary**: Displays actionable rollback commands (`./scripts/restore.sh`, `./scripts/extensions-manager.sh --dock-revert`, and emergency TTY shortcuts).

---

## Workflow 3: Automated Non-Interactive Installation

For scripting, automation, or direct CLI usage, macKali provides non-interactive flags via `scripts/install.sh` (or the top-level `./install.sh` wrapper).

### Step 1: Run Compatibility Check
Verify that your OS version, GNOME Shell release, and system utilities meet requirements:

```bash
./scripts/compat-check.sh
# or
./install.sh --check
```

### Step 2: Choose an Installation Preset

| Preset | Target Experience | Included Components |
| :--- | :--- | :--- |
| `minimal` | Lightweight macOS layout | WhiteSur cursors, dock config schema, window buttons on left |
| `balanced` | Authentic macOS polish | Minimal + Blur My Shell schema + Magic Lamp schema + GTK & Icons |
| `full` | macOS + 3D Compiz effects | Balanced + Desktop Cube schema + Wobbly Windows schema |

### Step 3: Run the Installer

Backups are enabled by default for non-interactive installations. To run with the recommended `balanced` preset:

```bash
./scripts/install.sh --preset balanced
```

To explicitly opt out of creating a backup before installation:

```bash
./scripts/install.sh --preset balanced --no-backup
```

To preview changes without touching files or settings (no backup created during dry-run):

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

## Workflow 4: Manual Component-by-Component Installation

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

## Upstream Updates & In-App Release Checking

macKali automatically queries the official GitHub Releases API on startup to alert you whenever a newer version or patch is published:

```bash
# Explicitly check for newer releases:
./install.sh --check-update

# Disable update check when running in offline or firewalled environments:
./install.sh --no-update-check --interactive
# or
./scripts/install.sh --no-update-check --preset balanced
```

When an update is detected, you can upgrade:
- **Git users**: Run `git pull && ./install.sh --interactive`
- **Archive users**: Download the latest release from [macKali Releases](https://github.com/realmadede/macKali/releases) and extract.

---

## Uninstallation & Rollback

### Scoped Uninstallation (Preserves Unrelated Changes)
To reverse only macKali-managed files and settings while keeping any unrelated desktop changes made after installation:

```bash
./scripts/uninstall.sh
```

### Full Snapshot Restoration from Backup
To restore the complete desktop `dconf` snapshot captured prior to installation:

```bash
./scripts/restore.sh
# or
./scripts/uninstall.sh --restore-backup
```

### Clean Removal of Cursors & Complete Purge
```bash
./scripts/uninstall.sh --purge
```

---

## Packaging Release Archives (Maintainers)

macKali includes a deterministic release packager that generates self-contained tarballs and SHA-256 manifests without modifying host settings:

```bash
./scripts/package-release.sh
```

Artifacts are written to `dist/macKali-v<VERSION>.tar.gz` and validated automatically against required inclusion/exclusion rules.

