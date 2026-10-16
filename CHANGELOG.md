# Changelog

All notable changes to the **macKali** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned / Upcoming
- Final verification of the initial release candidate (`v1.0.0-rc.1`).
- Community hardware testing feedback integration across diverse Kali rolling environments.
- Optional automated screenshot pipeline for live desktop showcase captures.

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
