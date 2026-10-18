# macKali

**An open-source macOS-inspired appearance customization project for Kali Linux GNOME, designed to adapt to recent and future GNOME releases.**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform: Kali Linux | GNOME](https://img.shields.io/badge/Platform-Kali%20Linux%20%7C%20GNOME-blueviolet.svg)](#)
[![Stable Release: v1.0.0](https://img.shields.io/badge/Release-v1.0.0-success.svg)](https://github.com/realmadede/macKali/releases)
[![macKali CI](https://github.com/realmadede/macKali/actions/workflows/ci.yml/badge.svg)](https://github.com/realmadede/macKali/actions/workflows/ci.yml)
[![Live Showcase](https://img.shields.io/badge/Live%20Showcase-mackali.madede.workers.dev-success.svg)](https://mackali.madede.workers.dev/)

macKali transforms the GNOME desktop environment on Kali Linux into a refined, high-performance macOS-like desktop experience. Built on the foundation of the macOS-inspired **WhiteSur cursor theme**, macKali provides a modular framework supporting both automated presets and manual installation.

🌐 **Live Showcase Portal**: [https://mackali.madede.workers.dev/](https://mackali.madede.workers.dev/)

---

## Dynamic GNOME Compatibility & Component Independence

macKali is engineered for Kali Linux Rolling and modern GNOME releases:

- **Dynamic Detection & 4-Tier Evaluation**: Rather than being permanently tied to a single version ceiling, macKali dynamically inspects your GNOME version and categorizes extensions into `VERIFIED_COMPATIBLE` (regression tested in CI/test suite), `REPORTED_COMPATIBLE` (declared by upstream release or EGO API), `UNSUPPORTED`, and `COMPATIBILITY_UNKNOWN`.
- **Tested vs. Evaluated Versions**: Compatibility manifests are evaluated against **GNOME Shell 45 through 50**. Future or upstream-declared versions are evaluated dynamically on demand; unknown future versions are handled conservatively (`COMPATIBILITY_UNKNOWN`) and are never forced to run without verification.
- **Independent 10-Component Architecture**: Universal components (wallpapers, cursors, icons, GTK themes) are decoupled from GNOME Shell versions. If an extension is unverified or unsupported on a newer GNOME release, macKali gracefully continues installing all other compatible components.
- **Rolling-Release Resilience**: Detects GNOME upgrades automatically and provides `./scripts/compat-check.sh` to re-evaluate components without downgrading GNOME or modifying Kali APT packages.

---

## Cursor Preview

![macKali WhiteSur Cursors Preview](assets/preview.png)

---

## Project Status: Official Stable Release (v1.0.0)

This repository provides a reproducible release pipeline and modular desktop customization suite:

- **Deterministic Release Packaging** ([`scripts/package-release.sh`](scripts/package-release.sh)): Produces verified, standalone `.tar.gz` distribution packages with bit-for-bit reproducibility and cryptographic SHA-256 checksums (`SHA256SUMS`).
- **Automated Release Pipeline** ([`.github/workflows/release.yml`](.github/workflows/release.yml)): Tag-triggered and dispatch packaging, validation test suite execution, and GitHub Release publishing.
- **Modern Static Website & Showcase Portal** ([`website/`](website/)): Craft-inspired static portal deployed at [mackali.madede.workers.dev](https://mackali.madede.workers.dev/) featuring responsive cards, dynamic wallpaper viewers, accessibility controls, and a self-contained build engine ([`website/build.sh`](website/build.sh)).
- **Interactive Terminal Wizard** ([`scripts/tui-installer.sh`](scripts/tui-installer.sh)): Guided terminal interface with `whiptail`/`dialog` support and ANSI fallback, environment inspection, safety backup toggles, and instant recovery instructions.
- **Modular Extension Manager** ([`scripts/extensions-manager.sh`](scripts/extensions-manager.sh)): Inspect compatibility, query metadata, download verified release bundles from `extensions.gnome.org` (EGO), and manage lifecycle states. Experimental 3D effects (`--with-magic-lamp`, `--with-wobbly`, `--with-cube`) remain strictly opt-in.
- **macOS Dock Layout Engine**: Centered bottom layout, intelligent autohide, 48px icons, dynamic transparency, and dots indicators via Dash to Dock—with strict preservation of user favorite applications and Kali security launchers.
- **Strict Pre-existing Asset Protection**: Distinguishes system/pre-existing extensions, GTK stylesheets, and Kvantum/Qt configurations from macKali-created files, ensuring pre-existing user configurations are preserved across repeated installs and uninstallation.
- **Appearance Foundation, Traffic Lights & 4K Wallpapers**: Light/Dark mode pairing, WhiteSur cursors, circular top-left traffic light window controls (`close,minimize,maximize:` with no hover glyphs) enabled by default for GTK3 and GTK4/libadwaita apps, plus optional Qt/Kvantum interior styling (without forcing X11/XCB on Wayland).
- **Safety, Scoped Reversal & Full Snapshot Recovery**: Automatic pre-installation backups by default (with explicit `--no-backup` opt-out), scoped uninstallation (`./scripts/uninstall.sh`) that preserves unrelated user settings, full snapshot restoration (`./scripts/restore.sh` or `./scripts/uninstall.sh --restore-backup`), and emergency virtual console (`Ctrl+Alt+F3`) recovery instructions.

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
│   ├── safety-and-removal.md   # Safety guarantees, scoped removal & recovery
│   └── troubleshooting.md      # Kali Linux troubleshooting & FAQ
├── extensions/         # Extension manifests, schema, and presets
│   ├── manifest-schema.json    # JSON Schema for extension verification
│   ├── manifests/              # Verified extension metadata (5 extensions)
│   └── presets/                # Minimal, Balanced, and Full presets
├── scripts/            # Management, packaging and installation automation
│   ├── backup.sh          # Timestamped dconf desktop backup utility
│   ├── compat-check.sh    # System detection and extension compatibility checker
│   ├── install.sh         # Central macKali installer engine
│   ├── package-release.sh # Deterministic release archiver & SHA-256 generator
│   ├── restore.sh         # Rollback utility
│   ├── tui-installer.sh   # Interactive terminal customization wizard
│   ├── uninstall.sh       # Safe asset removal utility
│   └── lib/common.sh      # Shared shell logging and detection library
├── themes/             # Visual theme packages
│   ├── cursors/        # WhiteSur cursor theme (src, dist, build, install)
│   ├── gtk/            # GTK 3/4 theme assets & providers
│   ├── icons/          # macOS icon sets & providers
│   └── wallpapers/     # Dynamic Day/Night 4K wallpapers
├── build.sh            # Root backward-compatible cursor build wrapper
├── install.sh          # Root backward-compatible installer wrapper
├── CHANGELOG.md        # Structured release history across all phases
├── VERSION             # Authoritative release version source (v1.0.0)
└── LICENSE             # GNU General Public License v3.0
```

---

## Quickstart & Installation

### 1. Verified Release Archive (Recommended)

Download the official standalone package and verify SHA-256 checksums before running:

```bash
# 1. Download stable release and checksum manifest
VERSION="1.0.0"
curl -sLO "https://github.com/realmadede/macKali/releases/download/v${VERSION}/macKali-v${VERSION}.tar.gz"
curl -sLO "https://github.com/realmadede/macKali/releases/download/v${VERSION}/SHA256SUMS"

# 2. Verify SHA-256 integrity
sha256sum -c SHA256SUMS

# 3. Extract and launch the interactive wizard
tar -xzf "macKali-v${VERSION}.tar.gz"
cd "macKali-v${VERSION}"
./install.sh --interactive
```

### 2. Git Clone Workflow (Development)
Run the guided terminal customization wizard with environment detection, preset picker, and safety confirmation:

```bash
git clone https://github.com/realmadede/macKali.git
cd macKali
./install.sh --interactive
```
*Automatically uses `whiptail` or `dialog` if present, with a clean ANSI plain-terminal fallback.*

### 3. Check for Updates & Upstream Releases
macKali automatically checks for new releases on startup (can be bypassed with `--no-update-check`). You can also check explicitly at any time:

```bash
./install.sh --check-update
```

### 4. Check System Compatibility
Inspect your Kali Linux environment, GNOME Shell version, and tool availability without altering any settings:

```bash
./scripts/compat-check.sh
# or
./install.sh --check
```

### 5. Install WhiteSur Cursors (Backward-Compatible)
Installs the precompiled cursor theme to `~/.local/share/icons/WhiteSur-cursors`:

```bash
./install.sh
```

For system-wide installation across all users:
```bash
sudo ./install.sh --system
```

### 6. Non-Interactive Preset Installation
Run the macKali installer non-interactively (automatic backup is enabled by default before modifying settings):

```bash
./scripts/install.sh --preset balanced
```

To explicitly opt out of creating a backup:
```bash
./scripts/install.sh --preset balanced --no-backup
```

To test without making any changes or creating backups:
```bash
./scripts/install.sh --preset balanced --dry-run
```

### 7. Toolkit Window Decoration Scope
- **GTK3 & GTK4 / Libadwaita applications**: Inherit top-left circular red, yellow, and green traffic lights automatically.
- **Browsers & Electron apps (Chrome, Firefox, VS Code)**: Draw custom client-side titlebars by default and require enabling native system titlebars in their preferences (see [docs/troubleshooting.md](docs/troubleshooting.md#7-application-specific-traffic-lights--titlebar-setup)).
- **Qt5 / Qt6 applications**: Kvantum styles interior widgets when installed (`./scripts/providers/qt-provider.sh --install`); on GNOME Wayland, Qt uses its own client-side window decoration plugin unless launched under Xwayland (`QT_QPA_PLATFORM=xcb <app>`).

### 8. Rollback & Uninstallation at Any Time
```bash
# Scoped uninstallation (reverses only macKali-managed changes, preserving unrelated user settings):
./scripts/uninstall.sh

# Restore full pre-installation desktop snapshot from backup:
./scripts/restore.sh
# or:
./scripts/uninstall.sh --restore-backup
```

---

## Installation Presets

macKali defines three structured tiers:

| Preset | Target User | Core Appearance & Controls | Extensions & Optional Effects |
| :--- | :--- | :--- | :--- |
| **Minimal** | Resource-conscious users | WhiteSur cursors, circular left traffic lights, dark/light GTK styling | Dash to Dock (`--extensions`), no animation extensions |
| **Balanced** *(Default)* | Everyday Kali desktop | WhiteSur cursors, circular left traffic lights, 4K wallpapers, GTK & icons | Dash to Dock + Blur My Shell (`--extensions`), optional `--with-magic-lamp` |
| **Full** | Power users & 3D effects | Balanced appearance suite | Balanced + opt-in `--with-magic-lamp`, `--with-wobbly`, `--with-cube` |

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
- **Strict User-Level Space**: macKali operates exclusively in user space (`~/.local/share/`, `~/.config/`, and user `dconf`). It does not run with or require root permissions.
- **Automatic Backups & Hard Failure Protection**: Settings are backed up automatically before modification (`scripts/backup.sh`), and installation aborts safely if a backup cannot be written.

For an exhaustive risk assessment and recovery scenarios, read [docs/safety-and-removal.md](docs/safety-and-removal.md).

---

## How to Remove macKali

We believe in complete user transparency:

### Option A: Default Scoped Uninstallation (Recommended)
Reverses only macKali-managed files and settings while preserving unrelated desktop changes made after installation:
```bash
./scripts/uninstall.sh
```

### Option B: One-Command Full Purge (`--purge`)
```bash
./install.sh --purge
# or
./scripts/uninstall.sh --purge
```
This removes installed cursors and assets, resets modified GNOME keys back to stock Kali Linux defaults, and deletes backup caches.

### Option C: 100% Manual Terminal Reset (No Scripts)
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
- [x] **Phase 2: GNOME Appearance Foundation**
  - Bundled 4K Light & Dark macOS wallpapers
  - Master appearance engine (`scripts/appearance.sh`) with per-setting snapshots & rollback
  - WhiteSur GTK & Shell theme provider (`scripts/providers/gtk-provider.sh`)
  - WhiteSur Icon theme provider (`scripts/providers/icon-provider.sh`)
  - Wallpaper provider (`scripts/providers/wallpaper-provider.sh`)
  - Libadwaita / GTK4 color-scheme native styling
  - Circular traffic-light window controls (`close,minimize,maximize:`)
- [x] **Phase 3: GNOME Extensions & Desktop Environment Automation**
  - Modular Extension Manager (`scripts/extensions-manager.sh`)
  - Official GNOME 50 release package verification from EGO
  - Dash to Dock macOS dock layout application (bottom, centered, 48px, autohide)
  - Strict preservation of favorite apps and Kali security launchers
  - Blur My Shell frosted glass overview styling
  - Compiz wobbly windows & magic lamp genie animations (opt-in)
  - Experimental Desktop Cube 3D transition integration (opt-in)
  - Dynamic forward-compatible 4-tier GNOME evaluation engine
- [x] **Phase 4: Interactive TUI Installer & Static Showcase Website**
  - [x] **Phase 4A: Interactive Terminal Customization Wizard**
    - Guided interactive wizard (`scripts/tui-installer.sh`, `./install.sh --interactive`)
    - Dynamic UI backend selection (`whiptail`, `dialog`, ANSI plain-terminal fallback)
    - Dynamic preset loading, safety backup defaults, component selection
  - [x] **Phase 4B: Modern Static Website & Showcase Portal**
    - Craft-inspired showcase and documentation portal (`website` branch)
    - Responsive card layout, interactive wallpaper viewer, accessible dark/light themes
    - Accessible clipboard copy with fallback and zero third-party framework dependencies
    - Self-contained static build engine (`website/build.sh`)
- [x] **Phase 5 & v1.0.0 Stable Release: Packaging, Safety Hardening & Distribution**
  - Authoritative Semantic Versioning system (`VERSION`, `v1.0.0`)
  - Deterministic release archiver (`scripts/package-release.sh`) with GNU tar reproducible flags and SHA-256 manifests
  - GitHub Actions automated release pipeline (`.github/workflows/release.yml`) with version-tag agreement checks
  - Hardened non-interactive backup defaults, Wayland-safe Qt/Kvantum provider, and scoped uninstallation
  - 69-test isolated automated verification suite (`tests/run-tests.sh`)

---

## Attribution & License

- **Cursors**: WhiteSur cursors are inspired by macOS and based on [capitaine-cursors](https://github.com/keeferrourke/capitaine-cursors) by Keefer Rourke.
- **License**: Released under the terms of the [GNU General Public License v3.0](LICENSE).
