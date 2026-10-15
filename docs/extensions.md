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

## 2. GNOME Shell 50.3 & Wayland Compatibility Findings

### Live Environment Verification
- **Target OS**: Kali Linux Rolling 2026.3
- **GNOME Shell**: 50.3
- **Display Server**: Wayland (`XDG_SESSION_TYPE=wayland`)

### Key Technical Findings:
1. **Official Release Artifacts on EGO**:
   All 5 extensions have released packages published directly on `extensions.gnome.org` declaring support for GNOME `50` in their official `metadata.json`.
2. **Pre-existing System Extensions**:
   On Kali Linux Rolling systems, `dash-to-dock@micxgx.gmail.com` may already be installed system-wide via the `gnome-shell-extension-dashtodock` Debian package (v106). macKali detects pre-existing system extensions automatically and **never attempts to overwrite or delete them**.
3. **Wayland Animation Compositing**:
   Under Wayland, window animation and effects extensions interact directly with Clutter and Mutter scene graphs. The Magic Lamp and Compiz Windows Effect extensions operate smoothly without X11 compositor hacks.
4. **Desktop Cube Workspace Behavior**:
   Desktop Cube provides Compiz-style 3D workspace transitions. On GNOME 50 Wayland, horizontal workspace navigation remains standard. macKali treats Desktop Cube as an **experimental opt-in** feature and **never modifies the user's workspace count or global shortcut bindings**.

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
3. Disable all GNOME Shell extensions instantly:
   ```bash
   gnome-extensions disable --all
   ```
4. Reset extension dconf paths if needed:
   ```bash
   dconf reset -f /org/gnome/shell/extensions/dash-to-dock/
   dconf reset -f /org/gnome/shell/extensions/blur-my-shell/
   dconf reset -f /org/gnome/shell/extensions/desktop-cube/
   dconf reset -f /org/gnome/shell/extensions/com/github/hermes83/
   ```
5. Return to the graphical desktop session:
   ```
   Ctrl + Alt + F2   # or Ctrl + Alt + F1
   ```
