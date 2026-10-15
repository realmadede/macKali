# macKali Manual Configuration Reference

This guide provides deep-dive configuration details for users who prefer configuring their GNOME desktop manually through `gsettings`, `dconf-cli`, and `gnome-extensions`.

---

## 1. Cursors

### File Locations
- User-level: `~/.local/share/icons/WhiteSur-cursors/`
- System-level: `/usr/share/icons/WhiteSur-cursors/`

### Applying via GSettings
```bash
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
gsettings set org.gnome.desktop.interface cursor-size 24
```

### X11 Default Cursor Fallback
Create or edit `~/.icons/default/index.theme`:
```ini
[Icon Theme]
Inherits=WhiteSur-cursors
```

---

## 2. Light & Dark Appearance Modes

GNOME 42+ and GNOME 45–51 provide native color-scheme negotiation for applications.

### Set Dark Mode (Default macOS Dark Experience)
```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

### Set Light Mode
```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
```

### Reset to Default System Scheme
```bash
gsettings reset org.gnome.desktop.interface color-scheme
```

---

## 3. macOS Wallpapers (Light & Dark Pairing)

GNOME automatically uses `picture-uri` when in light mode and `picture-uri-dark` when in dark mode.

### Applying macKali 4K Wallpapers Manually
```bash
# 1. Create user backgrounds directory
mkdir -p ~/.local/share/backgrounds/macKali

# 2. Copy bundled 4K wallpapers
cp themes/wallpapers/macOS-macKali-Light.png ~/.local/share/backgrounds/macKali/
cp themes/wallpapers/macOS-macKali-Dark.png ~/.local/share/backgrounds/macKali/

# 3. Configure GNOME background URIs
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/macKali/macOS-macKali-Light.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/macKali/macOS-macKali-Dark.png"
gsettings set org.gnome.desktop.background picture-options 'zoom'
```

---

## 4. GTK & Icon Themes

### GTK3 vs GTK4 / Libadwaita Architecture Note

> [!NOTE]
> - **GTK3 Applications**: Fully support external theming via `org.gnome.desktop.interface gtk-theme`. Setting `WhiteSur-Dark` themes all buttons, menus, headerbars, and controls.
> - **GTK4 / Libadwaita Applications**: Libadwaita intentionally compiles its own Adwaita stylesheet into the application binary and ignores `gtk-theme`. The official, supported mechanism for libadwaita applications is the `color-scheme` ('prefer-dark' or 'prefer-light').
> - **Why macKali Avoids Forced CSS Hacks**: Injecting custom CSS into `~/.config/gtk-4.0/gtk.css` often causes layout regressions, text clipping, and crashes across rolling GNOME updates. macKali does not force unsupported CSS overrides on libadwaita.

### Setting GTK Theme Manually
```bash
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
```

### Setting Icon Theme Manually
```bash
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
```

### Setting Shell Theme (Requires User Theme Extension)
```bash
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'
```

---

## 5. Window Manager Buttons & Fonts

### macOS Traffic Lights (Left Side)
```bash
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
```

To revert back to GNOME default (Right Side):
```bash
gsettings reset org.gnome.desktop.wm.preferences button-layout
```

### macOS Typography (Recommended SF Pro / Cantarell)
```bash
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 10'
```

---

## 3. Dock Configuration (Dash to Dock)

Settings are stored under schema `org.gnome.shell.extensions.dash-to-dock`.

### Manual GSettings Commands
```bash
# Position at bottom
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'

# Center floating dock
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false

# Autohide and intellihide
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true

# macOS-like 48px icon size with running indicator dots
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
```

Or apply the template from the repo:
```bash
dconf load / < config/dock/dash-to-dock.dconf
```

---

## 4. Animation Effects

### Magic Lamp (Genie Effect)
Schema: `org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect`

```bash
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect effect-time 400
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect unminimize-effect-time 400
```

### Compiz Wobbly Windows Effect
Schema: `org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect`

```bash
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect friction 3.5
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect spring-k 8.0
```

### Desktop Cube
Schema: `org.gnome.shell.extensions.desktop-cube`

```bash
gsettings set org.gnome.shell.extensions.desktop-cube cube-rotation-speed 1.0
gsettings set org.gnome.shell.extensions.desktop-cube enable-skybox true
```

---

## 5. Extensions Installation Methods & Manual CLI Setup

In Phase 3, macKali includes the automated Extension Manager (`./scripts/extensions-manager.sh`). For users wishing to perform all configuration manually:

### Method A: macKali Extension Manager CLI
```bash
# Verify compatibility against GNOME 50.3 Wayland
./scripts/extensions-manager.sh --compat

# Apply macOS dock styling without modifying favorite apps
./scripts/extensions-manager.sh --dock-config

# Apply balanced extensions (Dock + Blur My Shell)
./scripts/extensions-manager.sh --preset balanced

# Opt-in to Genie lamp animations
./scripts/extensions-manager.sh --enable compiz-alike-magic-lamp-effect@hermes83.github.com
```

### Method B: Direct Dconf Import for Dash to Dock
If Dash to Dock is already installed, configure the centered macOS dock layout with:
```bash
# 1. Backup existing dock configuration
dconf dump /org/gnome/shell/extensions/dash-to-dock/ > ~/dash-to-dock-backup.dconf

# 2. Apply macKali macOS dock profile
dconf load /org/gnome/shell/extensions/dash-to-dock/ < config/dock/dash-to-dock.dconf

# 3. Verify favorite applications remain untouched
gsettings get org.gnome.shell favorite-apps
```

To revert manually:
```bash
dconf reset -f /org/gnome/shell/extensions/dash-to-dock/
dconf load /org/gnome/shell/extensions/dash-to-dock/ < ~/dash-to-dock-backup.dconf
```

### Method C: Official EGO Bundle Download
Download verified release packages directly from `extensions.gnome.org`:
```bash
# Example: Blur My Shell for GNOME 50
curl -sL "https://extensions.gnome.org/download-extension/blur-my-shell@aunetx.shell-extension.zip?version_tag=76297" -o /tmp/bms.zip
gnome-extensions install /tmp/bms.zip
gnome-extensions enable blur-my-shell@aunetx
rm /tmp/bms.zip
```
