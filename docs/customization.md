# macKali Customization Guide

This guide details how to tweak and personalize your macKali installation to fit your specific workflow.

---

## 1. Customizing Presets

Presets are defined in `extensions/presets/` as structured JSON files:
- `minimal.json`: Baseline macOS layout.
- `balanced.json`: Standard macOS layout with blur and genie animations.
- `full.json`: Full aesthetic with 3D Compiz effects.

You can create your own custom preset by copying an existing preset:

```bash
cp extensions/presets/balanced.json extensions/presets/my-preset.json
```

---

## 2. Dock Tuning (Dash to Dock)

### Adjusting Dock Icon Size
macKali defaults to `48px`. For smaller displays (laptops) or larger 4K monitors:

```bash
# Set icon size to 40px (compact):
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40

# Set icon size to 64px (large):
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 64
```

### Dock Visibility Mode
```bash
# Keep dock always visible (no autohide):
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true

# Enable intelligent autohide (hides when windows overlap):
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
```

### Dock Magnification on Hover
```bash
gsettings set org.gnome.shell.extensions.dash-to-dock dock-magnification true
gsettings set org.gnome.shell.extensions.dash-to-dock magnify-size 64
```

---

## 3. Cursor Customization

### Cursor Sizing
WhiteSur cursors support multi-resolution scaling:
- Standard: `24`
- Medium: `32`
- Large: `48`

Change via:
```bash
gsettings set org.gnome.desktop.interface cursor-size 32
```

### Rebuilding with Custom SVG Colors
If you want custom accent colors for the cursors:
1. Edit the SVG source vectors in `themes/cursors/src/svg/`.
2. Recompile with:
   ```bash
   ./themes/cursors/build.sh
   ```
3. Reinstall with:
   ```bash
   ./themes/cursors/install.sh
   ```

---

## 4. Animation Tuning

### Magic Lamp Duration
By default, the genie minimize effect runs in `400ms`. For a snappier feel:
```bash
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect effect-time 250
```

### Wobbly Window Physics
Adjust elasticity and friction:
```bash
# Stiffer, faster wobble:
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect spring-k 10.0
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect friction 4.0

# Very loose, gelatinous wobble:
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect spring-k 5.0
gsettings set org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect friction 2.5
```
