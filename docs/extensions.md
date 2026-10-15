# GNOME Extensions Documentation & Integration Architecture (Phase 3)

This document provides comprehensive technical documentation for the GNOME Shell extension and dock integration foundation implemented in **macKali Phase 3**.

---

## 1. Supported Extensions & Upstream Metadata

macKali integrates five optional, upstream-maintained GNOME Shell extensions to provide a high-polish macOS desktop experience while strictly preserving Kali Linux functionality.

| Extension Name | UUID | Upstream Author | License | EGO PK | GNOME 50 Verified Release | Wayland Compatible |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: |
| **Dash to Dock** | `dash-to-dock@micxgx.gmail.com` | micheleg | GPL-2.0-or-later | 307 | v110 (tag 76105) | **Yes** |
| **Blur My Shell** | `blur-my-shell@aunetx` | aunetx | GPL-3.0-or-later | 3193 | v75 (tag 76297) | **Yes** |
| **Compiz Alike Magic Lamp Effect** | `compiz-alike-magic-lamp-effect@hermes83.github.com` | hermes83 | GPL-3.0-or-later | 3740 | v25 (tag 76122) | **Yes** |
| **Compiz Windows Effect** | `compiz-windows-effect@hermes83.github.com` | hermes83 | GPL-3.0-or-later | 3210 | v33 (tag 76121) | **Yes** |
| **Desktop Cube** | `desktop-cube@schneegans.github.com` | Simon Schneegans | GPL-3.0-or-later | 4648 | v35 (tag 76156) | **Yes** |

---

## 2. Dynamic GNOME Compatibility Architecture

macKali targets Kali Linux Rolling and is built with a forward-compatible architecture that adapts to recent and future GNOME Shell releases rather than being permanently tied to GNOME Shell 50.3.

### Four-Tier Compatibility Classification
Compatibility for each extension is evaluated across four distinct tiers:

1. **`VERIFIED_COMPATIBLE`**:
   The extension release has undergone automated regression testing in macKali's test suite directly on this GNOME version.
2. **`REPORTED_COMPATIBLE`**:
   The extension release explicitly declares support for this GNOME version in upstream metadata or verified dynamically via the `extensions.gnome.org` API, but has not yet been locally regression-tested.
3. **`UNSUPPORTED`**:
   The target GNOME version is below the extension's minimum version requirement (`min_gnome_version`) or has known fatal incompatibilities.
4. **`COMPATIBILITY_UNKNOWN`**:
   The target GNOME version is newer than declared in local manifests and unconfirmed via upstream network query. **Unknown compatibility is never assumed to be compatible.** macKali preserves GNOME's native validation and will not force an unverified extension to run.

### Tested vs. Declared Upstream Versions
| Extension UUID | Minimum GNOME | Declared Upstream Range | Regression-Tested in macKali |
| :--- | :---: | :---: | :---: |
| `dash-to-dock@micxgx.gmail.com` | 45 | 45, 46, 47, 48, 49, 50 | **GNOME 50** |
| `blur-my-shell@aunetx` | 46 | 46, 47, 48, 49, 50 | **GNOME 50** |
| `compiz-alike-magic-lamp-effect@hermes83.github.com` | 45 | 45, 46, 47, 48, 49, 50 | **GNOME 50** |
| `compiz-windows-effect@hermes83.github.com` | 49 | 49, 50 | **GNOME 50** |
| `desktop-cube@schneegans.github.com` | 45 | 45, 46, 47, 48, 49, 50 | **GNOME 50** |

### Independent Component Compatibility
macKali evaluates the 10 desktop customization components independently:
- **Universal Components**: Wallpapers, Cursors, Icons, and GTK Themes adhere to standard Freedesktop / XDG / Libadwaita standards and function identically across all modern GNOME releases.
- **Shell-Coupled Components**: GNOME Shell extensions are evaluated individually. If a future GNOME update causes an extension to become unsupported, macKali cleanly continues applying all other compatible components.

### Rolling-Release Resilience & Version Shifts
When Kali Linux Rolling updates GNOME Shell:
- Version changes between previous installations and current environment are automatically detected by `scripts/compat-check.sh` and `scripts/extensions-manager.sh --status`.
- macKali provides `scripts/extensions-manager.sh --compat` to recheck extension compatibility without altering system packages or downgrading system packages.
- macKali never modifies APT repositories, never pins Kali packages, and never disables GNOME's native extension compatibility checks.

---

## 3. Presets & Opt-in Policy

macKali implements three carefully gated presets:

```
+-------------------------------------------------------------------------+
| macKali Presets Architecture                                           |
+-------------------------------------------------------------------------+
| [Minimal]                                                               |
|   ├── WhiteSur Cursors + macOS Appearance Foundation (Themes/Wallpapers)|
|   └── Dash to Dock: macOS bottom-centered dock layout                   |
+-------------------------------------------------------------------------+
| [Balanced] (Recommended)                                                |
|   ├── All Minimal components                                            |
|   ├── Blur My Shell: Frosted glass panel & overview blur                |
|   └── Magic Lamp: Optional opt-in only (--with-magic-lamp)              |
+-------------------------------------------------------------------------+
| [Full]                                                                  |
|   ├── All Balanced components                                           |
|   ├── Compiz Windows Effect: Optional opt-in only (--with-wobbly)       |
|   └── Desktop Cube: Experimental opt-in only (--with-cube)              |
+-------------------------------------------------------------------------+
```

> [!IMPORTANT]
> Extensions are never force-enabled simply because a user selects a higher preset tier. Experimental or GPU-heavy animations (Magic Lamp, Wobbly Windows, Desktop Cube) require explicit user opt-in flags.

---

## 4. Dash to Dock macOS Layout

macKali provides an authentic macOS dock configuration applied via dconf:

```ini
[org/gnome/shell/extensions/dash-to-dock]
dock-position='BOTTOM'
extend-height=false
dock-fixed=false
autohide=true
intellihide=true
dash-max-icon-size=48
icon-size-fixed=false
show-trash=true
show-mounts=true
show-apps-at-top=false
custom-theme-shrink=true
transparency-mode='DYNAMIC'
running-indicator-style='DOTS'
```

### System Preservation Guarantees:
- **Favorite Applications**: `org.gnome.shell favorite-apps` is strictly preserved. macKali **never** overwrites the user's Kali security tool launchers (e.g., Metasploit, Burp Suite, Wireshark, CherryTree).
- **Dock Settings Snapshot**: Before applying dock settings, macKali exports the user's pre-existing dock dconf keys to `~/.config/macKali/backups/dash-to-dock-pre-mackali.dconf`. Reverting the dock restores this exact snapshot.

---

## 5. Extension Manager CLI Reference

The modular extension manager script is located at `scripts/extensions-manager.sh`:

```bash
# 1. Check GNOME 50.3 and Wayland compatibility
./scripts/extensions-manager.sh --compat

# 2. View current installation and enable status
./scripts/extensions-manager.sh --status

# 3. List all supported extension metadata
./scripts/extensions-manager.sh --list

# 4. Preview preset application without modifying system
./scripts/extensions-manager.sh --preset balanced --dry-run

# 5. Apply Balanced preset (Dock layout + Blur My Shell)
./scripts/extensions-manager.sh --preset balanced

# 6. Apply Balanced preset with Genie lamp animations
./scripts/extensions-manager.sh --preset balanced --with-magic-lamp

# 7. Apply Full preset with all optional effects
./scripts/extensions-manager.sh --preset full --with-magic-lamp --with-wobbly --with-cube

# 8. Apply only Dash to Dock styling
./scripts/extensions-manager.sh --dock-config

# 9. Revert Dash to Dock styling to user's original backup
./scripts/extensions-manager.sh --dock-revert

# 10. Completely restore extensions to pre-macKali state
./scripts/extensions-manager.sh --restore
```

---

## 6. Pre-existing Extension Protection & State Tracking

macKali maintains persistent state in `~/.config/macKali/extensions-state.json`:

```json
{
  "dash-to-dock@micxgx.gmail.com": {
    "pre_existing": true,
    "pre_existing_path": "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com",
    "pre_existing_version": "106",
    "pre_existing_enabled": true,
    "installed_by_mackali": false,
    "installed_version": null,
    "dock_config_applied": false,
    "dock_backup_file": null
  }
}
```

### Safety Rules:
1. **Never Delete Pre-existing Files**: Extensions installed system-wide (`/usr/share/...`) or previously in `~/.local/share/...` are tagged `pre_existing: true` and are never removed on uninstallation.
2. **Reversible Dconf Changes**: Settings applied by macKali can be reverted at any time using `./scripts/extensions-manager.sh --dock-revert` or `./scripts/restore.sh`.
3. **No Extension Version Check Disabling**: macKali **never** sets `org.gnome.shell disable-extension-version-validation=true`.

---

## 7. Emergency Recovery (Virtual Console)

If an extension misbehaves or causes a compositor freeze under Wayland:

1. Switch to a Linux virtual text console:
   ```
   Ctrl + Alt + F3
   ```
2. Log in with your Kali Linux credentials.
3. Choose the appropriate recovery action:

   - **Targeted Recovery (Preserves other user extensions)**:
     ```bash
     for ext in dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx compiz-alike-magic-lamp-effect@hermes83.github.com compiz-windows-effect@hermes83.github.com desktop-cube@schneegans.github.com; do
       gnome-extensions disable "$ext" 2>/dev/null || true
     done
     ./scripts/extensions-manager.sh --dock-revert
     ```
   - **Global Extension Safe Kill-switch (Native GNOME setting)**:
     ```bash
     gsettings set org.gnome.shell disable-user-extensions true
     ```
     *(To re-enable user extensions once logged in: `gsettings set org.gnome.shell disable-user-extensions false`)*

4. Revert extension dconf paths if needed:
   ```bash
   # Revert dock settings to pre-macKali backup:
   ./scripts/extensions-manager.sh --dock-revert

   # Reset effects schemas installed by macKali:
   dconf reset -f /org/gnome/shell/extensions/blur-my-shell/
   dconf reset -f /org/gnome/shell/extensions/desktop-cube/
   dconf reset -f /org/gnome/shell/extensions/com/github/hermes83/
   ```
5. Return to the graphical desktop session:
   ```
   Ctrl + Alt + F2   # or Ctrl + Alt + F1
   ```
