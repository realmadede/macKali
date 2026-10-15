# macKali Configuration Templates

This directory contains modular `dconf` configuration snippets for GNOME desktop settings, dock preferences, animations, and keybindings.

## Structure

```
config/
├── gnome/
│   ├── 00-interface.dconf       # Cursors, icons, GTK themes, and font rendering
│   └── 01-wm-preferences.dconf  # Window manager button layout (macOS left traffic lights)
├── dock/
│   └── dash-to-dock.dconf       # macOS-styled centered bottom dock configuration
├── animations/
│   ├── magic-lamp.dconf         # macOS genie minimize animation timing
│   ├── compiz-windows.dconf     # Compiz wobbly windows physics parameters
│   └── desktop-cube.dconf       # 3D workspace cube rotation parameters
└── keybindings/
    └── custom-shortcuts.dconf   # macOS-inspired workflow keyboard shortcuts
```

## Safety & Application

All configuration templates in this directory are non-destructive when applied via the official `macKali` installer script, which creates an automatic timestamped backup prior to modifying any keys.

To manually inspect or load individual settings:

```bash
# View current setting before changing
dconf read /org/gnome/desktop/wm/preferences/button-layout

# Manually load a snippet:
dconf load / < config/gnome/01-wm-preferences.dconf

# Revert to standard GNOME button layout:
dconf reset /org/gnome/desktop/wm/preferences/button-layout
```
