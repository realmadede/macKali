# Changelog

All notable changes to the **macKali** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned / Upcoming
- Comprehensive disposable-VM graphical validation across live Kali Linux GNOME Wayland and X11 environments (deferred from v1.0.0 initial release).
- Community hardware testing feedback integration across diverse Kali rolling environments.
- Optional automated screenshot pipeline for live desktop showcase captures.

---

## [1.0.0] - 2026-10-18

### First Official Stable Release

`v1.0.0` marks the first official stable release of **macKali**, delivering a modular, rootless macOS-inspired desktop customization suite for Kali Linux GNOME with hardened installation safety and scoped recovery.

### Added & Finalized
- **Modular macKali Desktop Customization**: Decoupled user-space providers for cursors (`themes/cursors/`), 4K day/night wallpapers (`scripts/providers/wallpaper-provider.sh`), GTK themes (`scripts/providers/gtk-provider.sh`), icon themes (`scripts/providers/icon-provider.sh`), and optional Qt/Kvantum styling (`scripts/providers/qt-provider.sh`).
- **Interactive Installer & Structured Presets**: Guided terminal setup wizard (`scripts/tui-installer.sh`, `./install.sh --interactive`) supporting `whiptail`, `dialog`, and plain-terminal ANSI fallback across `minimal`, `balanced`, and `full` presets.
- **WhiteSur Appearance & Cursor Integration**: Pre-built and source-buildable WhiteSur vector cursor theme paired with light and dark mode desktop appearance orchestration (`scripts/appearance.sh`).
- **Circular Traffic-Light Window Controls**: Authentic top-left circular Close (`#ff5f56`), Minimize (`#ffbd2e`), and Maximize (`#27c93f`) titlebar controls (`close,minimize,maximize:`) with 1:1 circular SVG geometry and isolated per-button hover glow (no internal hover glyphs).
- **GTK3 & GTK4 / Libadwaita Integration**: Scoped, delimited CSS injection in `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` alongside non-destructive `settings.ini` updates that preserve pre-existing user CSS rules and unrelated keys.
- **Optional Qt / Kvantum Integration**: User-space Kvantum configuration (`scripts/providers/qt-provider.sh`) that verifies Kvantum engine and complete `.kvconfig` + `.svg` theme resources before activation, preserves pre-existing `kvantum.kvconfig` and `10-mackali-qt.conf` files, and never forces `QT_QPA_PLATFORM=xcb` on GNOME Wayland sessions.
- **GNOME Extension Management & Dynamic Compatibility Detection**: Centralized extension manager (`scripts/extensions-manager.sh`) and compatibility checker (`scripts/compat-check.sh`) using a forward-compatible 4-tier evaluation model (`VERIFIED_COMPATIBLE`, `REPORTED_COMPATIBLE`, `UNSUPPORTED`, `COMPATIBILITY_UNKNOWN`) without artificial GNOME version ceilings. Experimental 3D effects (`--with-magic-lamp`, `--with-wobbly`, `--with-cube`) remain strictly opt-in.
- **Automatic Backups & Hardened Installation Safety**: Non-interactive and interactive installations automatically create timestamped backups (`scripts/backup.sh`) by default before modifying settings, provide an explicit `--no-backup` opt-out, keep `--dry-run` and `--check` free of backup creation, and abort immediately if backup creation fails.
- **Scoped Restoration vs. Full Snapshot Recovery**: Ordinary uninstallation (`scripts/uninstall.sh`) performs a scoped reversal of macKali-managed files and settings while preserving unrelated post-install desktop modifications; full point-in-time `dconf` snapshot restoration remains available via `./scripts/restore.sh` or `./scripts/uninstall.sh --restore-backup`.
- **Reproducible Release Packaging & GitHub Actions Automation**: Deterministic release tarball and `SHA256SUMS` generation (`scripts/package-release.sh`), automated 69-test isolated verification suite (`tests/run-tests.sh`), in-app release update checker (`--check-update`), and tag-verified GitHub Actions release publishing (`.github/workflows/release.yml`).

### Verification Notes
- All 69 automated sandbox, parser, lifecycle, and packaging tests pass in isolated environments.
- Comprehensive disposable-VM graphical validation across live Wayland/X11 sessions remains deferred following project owner verification on Kali Linux GNOME.

---

## [1.0.0-rc.1] - 2026-10-16

### Initial Release Candidate

This release candidate unifies the modular desktop customization architecture, compatibility engine, interactive installer wizard, showcase portal, and release distribution infrastructure developed across Phases 1 through 5.

### Added

#### Phase 1: Repository Foundation & Safety Infrastructure
- Preserved legacy WhiteSur vector cursor suite installation pipeline (`capitaine-cursors` derivative by Keefer Rourke) in `themes/cursors/`.
- Root user-space installer entry point (`./install.sh`) supporting both legacy cursor installation and modular feature flags.
- Isolated user-space backup engine (`scripts/backup.sh`) creating dated desktop configuration archives in `~/.config/mackali/backups/`.
- Targeted restoration utility (`scripts/restore.sh`) capable of inspecting, validating, and restoring prior desktop settings.
- Safe clean uninstall engine (`scripts/uninstall.sh`) with `--purge` flag removing macKali assets without disturbing personal files or unrelated extensions.
- Configuration schemas and directory layout (`config/dock`, `config/gnome`, `config/animations`, `config/keybindings`).

#### Phase 2: Appearance Foundation & Dynamic Theming
- Modular appearance configuration engine (`scripts/appearance.sh`) managing system styling rootlessly.
- High-resolution bundled wallpapers (`themes/wallpapers/macOS-macKali-Light.png` and `themes/wallpapers/macOS-macKali-Dark.png`) in 3840×2160 UHD.
- Dynamic Light and Dark mode desktop appearance switching (`--mode light|dark`).
- System GTK theme provider (`scripts/providers/gtk-provider.sh`) applying macOS-style window controls and Adwaita/Adw-gtk3 integration.
- Icon theme provider (`scripts/providers/icons-provider.sh`) configuring user-level icon suites.
- Desktop settings audit tools verifying host system preservation and non-destructive execution.

#### Phase 3: Extension Management, Dock Integration & Dynamic GNOME Compatibility
- Centralized extension manager (`scripts/extensions-manager.sh`) handling EGO downloads, hash verification, metadata inspection, and localized installation.
- 4-Tier GNOME extension compatibility engine:
  - `VERIFIED_COMPATIBLE`: Regression tested and verified on current platform.
  - `REPORTED_COMPATIBLE`: Declared compatible by upstream extension manifest, pending runtime test.
  - `UNSUPPORTED`: Explicitly marked incompatible with running GNOME version.
  - `COMPATIBILITY_UNKNOWN`: Unrecognized or future GNOME release; handled conservatively without forced execution.
- Forward-compatible detection engine rejecting hardcoded GNOME maximum versions, enabling safe operation across Kali Linux Rolling updates.
- Bottom floating macOS-inspired dock using Dash to Dock while strictly preserving pinned favorite applications and Kali security launchers.
- Independent component architecture: failure or incompatibility of an extension does not block wallpapers, cursors, or GTK styling.
- Guarded opt-in toggles for 3D desktop effects:
  - Compiz Magic Lamp minimize animation (`--with-magic-lamp`)
  - Compiz Windows Effect wobbly physics (`--with-wobbly`)
  - Desktop Cube 3D workspace switcher (`--with-cube`)
- Three structured configuration presets (`minimal`, `balanced`, `full`).

#### Phase 4A: Interactive Terminal Setup Wizard (TUI)
- Dedicated interactive installer (`scripts/tui-installer.sh`, accessible via `./install.sh --interactive` or `./install.sh -i`).
- Dynamic backend selection supporting `whiptail`, `dialog`, and a clean plain-terminal ANSI fallback.
- Step-by-step guidance: environment detection, preset selection, granular component customization, compatibility reporting, and confirmation.
- Default automated backup creation before any setting is applied, with explicit `--no-backup` override.
- Dry-run capability (`--dry-run`) allowing complete workflow preview with zero system modifications.

#### Phase 4B: Modern Static Showcase Portal
- Lightweight, self-contained static website in `website/` deployed to Cloudflare edge infrastructure.
- Tactile editorial design system inspired by Craft (`getcraft.com`), featuring warm paper surfaces, floating pill navigation, and responsive typography (Sofia Sans).
- Fully responsive layout verified down to 320px mobile viewports with horizontal scroll containment and accessible keyboard navigation.
- Accessible 1-click clipboard installation copy bar above the fold.
- Interactive FAQ accordion clarifying rootless execution, rollback procedures, rolling updates, and security tool isolation.
- Dark and Light mode theme toggle with persistent storage and system preference detection.
- Segmented 4K wallpaper showcase viewer (`4K Light Sunrise` / `4K Dark Midnight`).
- Self-contained build script (`website/build.sh`) producing validated `website/dist/` without Node.js or npm dependencies.

#### Phase 5: Release Packaging, Integrity & Distribution
- Single authoritative version source: `VERSION` file in repository root.
- Automated release packaging engine (`scripts/package-release.sh`) creating deterministic distribution archives (`macKali-v1.0.0-rc.1.tar.gz`).
- Release checksum manifest (`SHA256SUMS`) for independent artifact verification.
- Comprehensive package extraction test validating root entry points (`./install.sh --help`, `./scripts/compat-check.sh`) in standalone environments outside of Git.
- GitHub Actions release pipeline (`.github/workflows/release.yml`) enforcing tag-version alignment, test execution, checksum validation, and artifact generation.
- In-app upstream release update checker (`--check-update` and `--no-update-check`) querying GitHub Releases API with SemVer evaluation.
- Expanded 41-test automated regression suite covering versioning, packaging, checksum verification, file inclusions, standalone execution, and update checking.

### Security & Safety Principles
- **Rootless Operation**: User-level customizations execute within user space (`~/.local/share`, `~/.config`, user dconf) without requiring `sudo`.
- **System Isolation**: Never modifies APT repositories, package pinning, system services, security utilities, or `/etc`.
- **Non-Destructive Restoration**: All changes are tracked in timestamped backups and reversible via `./scripts/restore.sh` or `./scripts/uninstall.sh --purge`.
- **GNOME Validation Preservation**: Never forces incompatible extensions or disables GNOME Shell's native extension verification.
