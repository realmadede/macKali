# macKali Troubleshooting & FAQ

This guide addresses common questions, compatibility edge cases, and recovery procedures on Kali Linux.

---

## 1. Kali Linux Desktop Session

### Problem: Running XFCE instead of GNOME
Kali Linux default installations frequently use XFCE as the default lightweight desktop. macKali is specifically built for the **GNOME** desktop environment.

**Check your current desktop environment:**
```bash
echo $XDG_CURRENT_DESKTOP
```

**Resolution:**
If running XFCE, install GNOME Shell on Kali Linux:
```bash
sudo apt update
sudo apt install -y kali-desktop-gnome
```
At login (GDM), click the gear icon to select "GNOME" or "GNOME on Wayland".

---

## 2. Cursor Issues

### Problem: Cursors do not update in Flatpak or Snap apps
Flatpak and Snap applications run in sandboxed environments that do not automatically read `~/.local/share/icons`.

**Resolution for Flatpak:**
```bash
flatpak --user override --filesystem=$HOME/.local/share/icons:ro
flatpak --user override --env=XCURSOR_THEME=WhiteSur-cursors
```

**Resolution for System-wide Consistency:**
Install the cursors system-wide:
```bash
sudo ./themes/cursors/install.sh --system
```

### Problem: Default cursor appears on desktop background or root window
In X11 sessions, the X server requires a fallback theme set in `~/.icons/default/index.theme`:
```bash
mkdir -p ~/.icons/default
cat <<EOF > ~/.icons/default/index.theme
[Icon Theme]
Inherits=WhiteSur-cursors
EOF
```

---

## 3. Cursor Compilation Dependencies

### Problem: `rsvg-convert: command not found` or `xcursorgen: command not found`
When executing `./themes/cursors/build.sh` or `./build.sh`, the build aborts due to missing SVG converters.

**Resolution:**
```bash
sudo apt update
sudo apt install -y librsvg2-bin xorg-xcursorgen python3 git
```

---

## 4. GNOME Extensions & Shell Issues

### Problem: Restarting GNOME Shell after applying settings
- **On X11**: Press `Alt + F2`, type `r`, and press `Enter`.
- **On Wayland**: The Wayland compositor cannot be restarted in-place. You must log out and log back in to reload GNOME Shell.

### Problem: Extension marked "Incompatible" after GNOME update
Kali Linux is a rolling distribution. When GNOME Shell updates (e.g., from GNOME 47 to 50), extensions may temporarily fail version checks.

**Resolution:**
1. Check the extension manifest in `extensions/manifests/` for supported versions.
2. If using GNOME Extensions CLI, check status with:
   ```bash
   gnome-extensions list --status
   ```
3. Never force `disable-extension-version-validation` unless testing in a development environment.

---

## 5. Recovery & Rollback

### Revert All GNOME Desktop Changes
macKali creates automated backups prior to applying presets:

```bash
# List available backups:
./scripts/restore.sh --list

# Restore the most recent backup:
./scripts/restore.sh
```

### Cleanly Remove macKali Assets & Reset Settings
```bash
# Revert to latest backup:
./scripts/uninstall.sh --restore-backup

# Or complete purge back to Kali Linux system defaults:
./scripts/uninstall.sh --purge
```

---

## 6. Emergency Recovery via Virtual Console (TTY)

If an experimental extension or Wayland compositor issue locks the graphical interface:

1. **Switch to Virtual Console 3**:
   Press `Ctrl + Alt + F3`.
2. **Log In**:
   Enter your Kali Linux username and password.
3. **Disable Extensions Safely**:
   - To disable **only macKali-managed extensions** (preserving your personal extensions):
     ```bash
     for ext in dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx compiz-alike-magic-lamp-effect@hermes83.github.com compiz-windows-effect@hermes83.github.com desktop-cube@schneegans.github.com; do
       gnome-extensions disable "$ext" 2>/dev/null || true
     done
     ```
   - Or to instantly disable **all user extensions globally** via GNOME's native kill-switch:
     ```bash
     gsettings set org.gnome.shell disable-user-extensions true
     ```
4. **Revert Dock Settings Safely (Preserving Pre-existing Configurations)**:
   ```bash
   ./scripts/extensions-manager.sh --dock-revert
   ```
   If needed, reset schemas for animation extensions installed by macKali:
   ```bash
   dconf reset -f /org/gnome/shell/extensions/blur-my-shell/
   dconf reset -f /org/gnome/shell/extensions/desktop-cube/
   dconf reset -f /org/gnome/shell/extensions/com/github/hermes83/
   ```
5. **Switch Back to the Graphical Desktop**:
   Press `Ctrl + Alt + F2` (or `Ctrl + Alt + F1` depending on display manager).
   The desktop will resume without the offending extension.

For full disaster recovery steps and manual commands, see [docs/safety-and-removal.md](safety-and-removal.md).
