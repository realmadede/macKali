# macKali Architecture and Repository Organization

## Overview

**macKali** is a modular macOS-inspired customization framework designed for Kali Linux and GNOME desktop environments. Built upon the original WhiteSur cursor theme, macKali structures desktop customization into cohesive, maintainable layers: themes, extensions, configuration templates, automation scripts, and documentation.

---

## Directory Hierarchy

```
macKali/
├── assets/                     # Screenshots, previews, and artwork
│   ├── preview.png             # Master WhiteSur cursor preview
│   └── README.md
├── build.sh                    # Root build wrapper (delegates to themes/cursors/build.sh)
├── install.sh                  # Root installer wrapper (backward-compatible)
├── LICENSE                     # GNU General Public License v3.0
├── README.md                   # Project overview, quickstart, and roadmap
├── config/                     # GNOME settings templates (dconf / gsettings)
│   ├── animations/             # Compiz windows, magic lamp, and desktop cube settings
│   ├── dock/                   # Dash to Dock macOS-style configuration
│   ├── gnome/                  # Interface, window manager button layout, fonts
│   ├── keybindings/            # macOS-like keyboard navigation shortcuts
│   └── README.md
├── docs/                       # Project documentation
│   ├── architecture.md         # Repository organization and architecture
│   ├── installation.md         # Automated and manual installation workflows
│   ├── manual-configuration.md # Step-by-step manual setup instructions
│   ├── extensions.md           # GNOME extension manifests and compatibility
│   ├── customization.md        # Customizing themes, dock, and presets
│   └── troubleshooting.md      # Diagnostics and issue resolution
├── extensions/                 # Extension manifests, schema, and presets
│   ├── manifest-schema.json    # JSON Schema for extension verification
│   ├── manifests/              # Verified metadata for target extensions
│   │   ├── blur-my-shell.json
│   │   ├── compiz-alike-magic-lamp-effect.json
│   │   ├── compiz-windows-effect.json
│   │   ├── dash-to-dock.json
│   │   └── desktop-cube.json
│   ├── presets/                # Modular installation presets
│   │   ├── minimal.json
│   │   ├── balanced.json
│   │   └── full.json
│   └── README.md
├── scripts/                    # Automation and management scripts
│   ├── appearance.sh           # Master appearance engine (themes, icons, wallpapers, light/dark)
│   ├── backup.sh               # Timestamped dconf/gsettings backup utility
│   ├── compat-check.sh         # Non-destructive environment and version checker
│   ├── install.sh              # Central installer engine
│   ├── restore.sh              # Rollback and backup restoration tool
│   ├── uninstall.sh            # Asset removal and cleanup tool
│   ├── README.md
│   ├── lib/
│   │   └── common.sh           # Shared shell helper functions and logging
│   └── providers/              # Modular asset and provider drivers
│       ├── gtk-provider.sh     # WhiteSur GTK & Shell user-space installer
│       ├── icon-provider.sh    # WhiteSur Icon theme user-space installer
│       └── wallpaper-provider.sh # 4K wallpaper installer and downloader
└── themes/                     # Visual assets and theme packages
    ├── cursors/                # WhiteSur cursor sources, build scripts, and compiled dist
    │   ├── build.sh            # X11/SVG cursor build compiler
    │   ├── install.sh          # Cursor installation utility
    │   ├── preview.png
    │   ├── dist/               # Compiled binary xcursors and scalable SVGs
    │   ├── src/                # SVG vectors and hotspot definitions
    │   └── README.md
    ├── gtk/                    # GTK theme provider manifest and documentation
    │   ├── theme-provider.json
    │   └── README.md
    ├── icons/                  # Icon theme provider manifest and documentation
    │   ├── icon-provider.json
    │   └── README.md
    ├── shell/                  # GNOME Shell theme provider manifest and documentation
    │   ├── theme-provider.json
    │   └── README.md
    └── wallpapers/             # Bundled 4K wallpapers and provider manifest
        ├── macOS-macKali-Light.png
        ├── macOS-macKali-Dark.png
        ├── wallpaper-provider.json
        └── README.md
```

---

## Architectural Principles

### 1. User-Level Preference
System-wide modifications require root access and risk interfering with Kali Linux package updates. macKali defaults to user-level paths:
- Icons & Cursors: `~/.local/share/icons/`
- Themes: `~/.local/share/themes/`
- Extensions: `~/.local/share/gnome-shell/extensions/`
- Configuration: user `dconf` database via `gsettings`

### 2. Backup Before Modification
The script `scripts/backup.sh` captures current desktop and shell dconf dumps prior to applying configurations, guaranteeing one-command rollback via `scripts/restore.sh`.

### 3. Preserved Cursor Heritage
The foundational WhiteSur cursor build pipeline (`themes/cursors/src` -> `themes/cursors/dist`) is completely preserved. The build and installation scripts function autonomously within `themes/cursors/` while maintaining root-level wrappers (`./build.sh` and `./install.sh`).

### 4. Explicit Compatibility & Verification
Extension UUIDs and compatibility ranges are verified against upstream source repositories. Manifests use a formal schema (`extensions/manifest-schema.json`) where any unverified attributes are recorded explicitly.
