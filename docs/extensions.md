# GNOME Extensions Documentation & Compatibility Matrix

This document provides technical documentation on the five supported GNOME extensions in **macKali**, their manifests, schema validation, and preset mapping.

---

## Supported Extensions Overview

### 1. Dash to Dock
- **UUID**: `dash-to-dock@micxgx.gmail.com`
- **Role**: Replaces the hidden GNOME dash overview with an always-accessible or intellihiding macOS-styled dock at the bottom of the screen.
- **Upstream Repository**: [https://github.com/micheleg/dash-to-dock](https://github.com/micheleg/dash-to-dock)
- **GNOME Extensions URL**: [https://extensions.gnome.org/extension/307/dash-to-dock/](https://extensions.gnome.org/extension/307/dash-to-dock/)
- **Configuration Schema**: `org.gnome.shell.extensions.dash-to-dock`
- **Known Conflicts**: `dash-to-panel@jderose9.github.com`, `ubuntu-dock@ubuntu.com`.

### 2. Desktop Cube
- **UUID**: `desktop-cube@schneegans.github.com`
- **Role**: Provides 3D panoramic cube rotation between GNOME virtual workspaces, reminiscent of Compiz Fusion.
- **Upstream Repository**: [https://github.com/Schneegans/Desktop-Cube](https://github.com/Schneegans/Desktop-Cube)
- **GNOME Extensions URL**: [https://extensions.gnome.org/extension/4648/desktop-cube/](https://extensions.gnome.org/extension/4648/desktop-cube/)
- **Configuration Schema**: `org.gnome.shell.extensions.desktop-cube`
- **Known Conflicts**: Custom workspace switcher overrides.

### 3. Compiz Windows Effect
- **UUID**: `compiz-windows-effect@hermes83.github.com`
- **Role**: Emulates classic wobbly window physics using physical spring and friction models when moving and resizing windows.
- **Upstream Repository**: [https://github.com/hermes83/compiz-windows-effect](https://github.com/hermes83/compiz-windows-effect)
- **GNOME Extensions URL**: [https://extensions.gnome.org/extension/3210/compiz-windows-effect/](https://extensions.gnome.org/extension/3210/compiz-windows-effect/)
- **Configuration Schema**: `org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect`
- **Known Conflicts**: `burn-my-windows@schneegans.github.com` (if wobbly option enabled), `wobbly-windows@hermes83.github.com`.

### 4. Compiz Alike Magic Lamp Effect
- **UUID**: `compiz-alike-magic-lamp-effect@hermes83.github.com`
- **Role**: Emulates macOS Genie minimize and restore animations as windows shrink into the dock.
- **Upstream Repository**: [https://github.com/hermes83/compiz-alike-magic-lamp-effect](https://github.com/hermes83/compiz-alike-magic-lamp-effect)
- **GNOME Extensions URL**: [https://extensions.gnome.org/extension/3740/compiz-alike-magic-lamp-effect/](https://extensions.gnome.org/extension/3740/compiz-alike-magic-lamp-effect/)
- **Configuration Schema**: `org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect`
- **Known Conflicts**: Other window minimizing animation plugins.

### 5. Blur My Shell
- **UUID**: `blur-my-shell@aunetx`
- **Role**: Applies real-time Gaussian blur and frosted glass acrylic effects to the GNOME top bar, application overview, dock, and lock screen.
- **Upstream Repository**: [https://github.com/aunetx/blur-my-shell](https://github.com/aunetx/blur-my-shell)
- **GNOME Extensions URL**: [https://extensions.gnome.org/extension/3193/blur-my-shell/](https://extensions.gnome.org/extension/3193/blur-my-shell/)
- **Configuration Schema**: `org.gnome.shell.extensions.blur-my-shell`
- **Known Conflicts**: Dash to Dock corner radius glitch if not configured in settings.

---

## Verified Compatibility Matrix

| Extension | GNOME 45 | GNOME 46 | GNOME 47 | GNOME 48 | GNOME 49 | GNOME 50 | GNOME 51 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Dash to Dock** | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **Desktop Cube** | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **Compiz Windows Effect** | Tag v27* | Tag v28* | Tag v30* | Tag v31* | Yes | Yes | Yes |
| **Magic Lamp Effect** | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **Blur My Shell** | v61* | Yes | Yes | Yes | Yes | Yes | Yes |

*\* Requires specific release tags or downloads for GNOME 45-48.*

---

## Presets Mapping

| Extension | Minimal | Balanced | Full |
| :--- | :---: | :---: | :---: |
| **Dash to Dock** | Included | Included | Included |
| **Blur My Shell** | - | Included | Included |
| **Magic Lamp Effect** | - | Included | Included |
| **Compiz Windows Effect** | - | - | Included |
| **Desktop Cube** | - | - | Included |

---

## Phase 1 Extension Policy

> [!IMPORTANT]
> In accordance with Phase 1 safety constraints, macKali does **not** install extensions automatically during this phase. Extension manifests establish verified UUIDs, schemas, and compatibility ranges in preparation for Phase 2 automation.
