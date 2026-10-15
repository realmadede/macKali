# macKali

**macOS-inspired GNOME Desktop Customization Framework for Kali Linux**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform: Kali Linux / GNOME](https://img.shields.io/badge/Platform-Kali%20Linux%20%7C%20GNOME-blueviolet.svg)](#)
[![Status: Phase 1 Architecture](https://img.shields.io/badge/Status-Phase%201%20Complete-green.svg)](#)

macKali transforms the GNOME desktop environment on Kali Linux into a refined, high-performance macOS-like desktop experience. Built on the foundation of the macOS-inspired **WhiteSur cursor theme**, macKali provides a modular framework supporting both automated presets and manual installation.

---

## Cursor Preview

![macKali WhiteSur Cursors Preview](assets/preview.png)

---

## Project Status: Phase 1

This repository has transitioned from the original standalone cursor repository into a structured, modular customization suite:

- **Preserved Core**: The complete WhiteSur cursor theme (sources, compilation pipeline, and pre-built dist assets) is 100% functional and backward-compatible.
- **Architectural Foundation**: Directory layouts for GTK themes, Shell themes, icons, wallpapers, extensions, dconf configs, and automation scripts are established.
- **Safety & Rollback**: Automatic non-destructive backups (`scripts/backup.sh`) and instant rollback (`scripts/restore.sh`).
- **Verified Extension Manifests**: Formal JSON schema and verified metadata for Dash to Dock, Desktop Cube, Compiz Windows Effect, Compiz Alike Magic Lamp Effect, and Blur My Shell.
- **Phase 1 Deliverables Complete**: No desktop settings or extensions are altered without explicit user invocation.

---

## Repository Structure

```
macKali/
├── assets/             # Screenshots, previews, and artwork
├── config/             # GNOME settings templates (dconf/gsettings)
│   ├── animations/     # Compiz effects, genie lamp, and 3D cube
│   ├── dock/           # Dash to Dock macOS-style configuration
│   ├── gnome/          # Button layouts (left traffic lights) and fonts
│   └── keybindings/    # macOS-style navigation shortcuts
├── docs/               # Detailed guides
│   ├── architecture.md         # Architecture and design principles
│   ├── installation.md         # Automated and manual installation
│   ├── manual-configuration.md # Deep-dive manual configuration
│   ├── extensions.md           # Extension manifests and compatibility matrix
│   ├── customization.md        # Preset tuning and options
│   └── troubleshooting.md      # Kali Linux troubleshooting & FAQ
├── extensions/         # Extension manifests, schema, and presets
│   ├── manifest-schema.json    # JSON Schema for extension verification
│   ├── manifests/              # Verified extension metadata (5 extensions)
│   └── presets/                # Minimal, Balanced, and Full presets
├── scripts/            # Management and installation automation
│   ├── backup.sh       # Timestamped dconf desktop backup utility
│   ├── compat-check.sh # System detection and extension compatibility checker
│   ├── install.sh      # Central macKali installer engine
│   ├── restore.sh      # Rollback utility
│   ├── uninstall.sh    # Safe asset removal utility
│   └── lib/common.sh   # Shared shell logging and detection library
├── themes/             # Visual theme packages
│   ├── cursors/        # WhiteSur cursor theme (src, dist, build, install)
│   ├── gtk/            # (Planned Phase 2) GTK 3/4 themes
│   ├── icons/          # (Planned Phase 2) macOS squircle icon sets
│   ├── shell/          # (Planned Phase 2) GNOME Shell panel theme
│   └── wallpapers/     # (Planned Phase 2) Dynamic Day/Night wallpapers
├── build.sh            # Root backward-compatible cursor build wrapper
├── install.sh          # Root backward-compatible installer wrapper
└── LICENSE             # GNU General Public License v3.0
```

---

## Quickstart & Installation

### 1. Check System Compatibility
Inspect your Kali Linux environment, GNOME Shell version, and tool availability without altering any settings:

```bash
./scripts/compat-check.sh
# or
./install.sh --check
```

### 2. Install WhiteSur Cursors (Backward-Compatible)
Installs the precompiled cursor theme to `~/.local/share/icons/WhiteSur-cursors`:

```bash
./install.sh
```

For system-wide installation across all users:
```bash
sudo ./install.sh --system
```

### 3. Automated Customization Installer
Run the macKali installer with safety backup and preset selection:

```bash
./scripts/install.sh --preset balanced --backup
```

To test without making changes:
```bash
./scripts/install.sh --preset balanced --dry-run
```

### 4. Rollback at Any Time
If you ever want to revert desktop changes back to your initial state:

```bash
./scripts/restore.sh
```

---

## Installation Presets

macKali defines three structured tiers:

| Preset | Target User | Included in Phase 1 | Planned for Phase 2 |
| :--- | :--- | :--- | :--- |
| **Minimal** | Resource-conscious users | WhiteSur cursors, left traffic light buttons, dock config schema | Dash to Dock extension, base GTK theme |
| **Balanced** *(Default)* | Everyday Kali desktop | WhiteSur cursors, left buttons, dock schema, blur & genie schemas | Dash to Dock, Blur My Shell, Magic Lamp, GTK, Icons |
| **Full** | Power users & nostalgia | WhiteSur cursors, left buttons, all animation schemas | All 5 extensions (including Desktop Cube & Compiz Windows) |

See [docs/extensions.md](docs/extensions.md) for full preset and extension specifications.

---

## Manual Installation Workflow

Prefer configuring individual components manually? Full step-by-step instructions for `gsettings`, `dconf`, and manual extension setup are available in [docs/manual-configuration.md](docs/manual-configuration.md).

---

## Building Cursors from Source

Pre-built cursor binaries are already provided in `themes/cursors/dist/`. To rebuild after modifying SVGs:

```bash
# Install build tools:
sudo apt install -y xorg-xcursorgen librsvg2-bin python3 git

# Run build:
./build.sh
```

---

## Safety, System Impact & Risk Assessment

Will macKali break or disrupt your Kali Linux installation? **No.**
- **No System Tool Changes**: Penetration testing tools (Nmap, Metasploit, Wireshark, Burp Suite, etc.), system packages, network drivers, and kernel modules are completely untouched.
- **Strict User-Level Space**: macKali operates exclusively in user space (`~/.local/share/` and user `dconf`). It does not run with or require root permissions.
- **Automatic Backups**: Settings are backed up before modification (`scripts/backup.sh`), enabling single-command rollback.

For an exhaustive risk assessment and recovery scenarios, read [docs/safety-and-removal.md](docs/safety-and-removal.md).

---

## How to Completely Remove macKali (Zero Traces)

We believe in complete user transparency. If you ever want to revert your system to 100% stock Kali Linux defaults:

### One-Command Full Purge:
```bash
./install.sh --purge
# or
./scripts/uninstall.sh --purge
```
This removes installed cursors, resets all modified GNOME keys back to original Kali Linux defaults, and deletes backup caches.

### Or 100% Manual Terminal Reset (No Scripts):
```bash
gsettings reset org.gnome.desktop.interface cursor-theme
gsettings reset org.gnome.desktop.wm.preferences button-layout
rm -rf ~/.local/share/icons/WhiteSur-cursors ~/.config/macKali
```
See [docs/safety-and-removal.md](docs/safety-and-removal.md) for full manual recovery details.

---

## Roadmap

- [x] **Phase 1: Architecture & Foundation**
  - Modular directory organization
  - Preserved cursor build and installation pipelines
  - Backup and restore utilities
  - Extension manifests schema and presets
  - Complete documentation suite
- [ ] **Phase 2: Automated Extensions & Themes Implementation**
  - Automated extension installation via GNOME Extensions CLI / GitHub releases
  - WhiteSur GTK 3 / 4 theme packaging and libadwaita integration
  - WhiteSur GNOME Shell theme integration
  - macOS squircle icon pack packaging (with custom Kali tool icons)
  - Dynamic Day/Night wallpapers with GNOME background XML schedulers
  - Interactive TUI installer wizard

---

## Attribution & License

- **Cursors**: WhiteSur cursors are inspired by macOS and based on [capitaine-cursors](https://github.com/keeferrourke/capitaine-cursors) by Keefer Rourke.
- **License**: Released under the terms of the [GNU General Public License v3.0](LICENSE).
