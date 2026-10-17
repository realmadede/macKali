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

---

## 7. Application-Specific Traffic Lights & Titlebar Setup

While GTK 4, Libadwaita, and GTK 3 applications display circular traffic lights automatically, browsers, Electron suites, and Qt apps require one-time configuration to adopt native system window controls:

### Google Chrome, Chromium & Brave
1. **Method 1:** Right-click an empty space in the top tab strip (next to the `+` button) and check **"Use system title bar and borders"**.
2. **Method 2:** Navigate to `Settings` &rarr; `Appearance` and enable **"Use system title bar and borders"**.
3. Window controls immediately move to the top-left in authentic macOS Red, Yellow, and Green circles.

### Mozilla Firefox, LibreWolf & Waterfox
1. Right-click any blank area of the navigation bar or tab strip and select **"Customize Toolbar..."**.
2. In the bottom-left corner of the window, check the **"Title Bar"** checkbox.
3. Click **"Done"** to apply. Firefox will now use the native system header with top-left circular controls.

### Visual Studio Code, VSCodium & Cursor
1. Open Settings (`Ctrl + ,` or File &rarr; Preferences &rarr; Settings).
2. Search for `window.titleBarStyle` in the search bar.
3. Change the dropdown setting from `custom` to **`native`**.
4. Reload or restart the editor to enjoy full native titlebars with traffic lights.

### Electron Applications (Discord, Slack, Obsidian, Spotify)
- **In-App Option:** In the application's Preferences or Window settings, set the titlebar style to **"Native"**.
- **Wayland Flag Option:** Start the application with `--enable-features=UseOzonePlatform --ozone-platform=wayland` for native Wayland compositor integration.

### Sandboxed Flatpak & Snap Applications
Flatpak containers are sandboxed from reading `~/.config/gtk-4.0` by default. Grant read-only access to user themes:
```bash
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
```
Or grant *Filesystem &rarr; User Configuration* access via the **Flatseal** GUI utility.

### Qt 5 & Qt 6 Applications (Wireshark, VirtualBox)
- Interior controls (menus, buttons, tabs, tables, packet lists) are themed via Kvantum (`./scripts/providers/qt-provider.sh --install`).
- Window buttons are placed on the top-left in macOS layout order (`close,minimize,maximize:`).
- On GNOME Wayland, Qt 6 uses its internal client-side decoration plugin with monochrome icons. If server-side decorations are desired, launch via Xwayland:
  ```bash
  QT_QPA_PLATFORM=xcb wireshark &
  ```

---

## 8. Supported Linux Distributions & Desktop Environment Tiers

macKali adheres to POSIX shell standards and standard FreeDesktop paths (`~/.config`, `~/.local/share`). It runs across:

* **Supported Distributions:** Debian (12/13/Testing/Sid), Ubuntu (22.04 LTS, 24.04 LTS, 24.10), Fedora Workstation (39 to 42+), Arch Linux / Manjaro, and Pop!_OS.
* **Desktop Environment Tiers:**
  * **Tier 1 — Full Experience (GNOME Shell 42 to 50+):** Full native GTK 4/Libadwaita traffic lights, Dash to Dock centered bottom layout, dynamic dark/light mode, and verified extension bundles.
  * **Tier 2 — Supported via Fallbacks (XFCE):** Configures `xfwm4` window borders, WhiteSur XFCE themes, and left-hand button layouts (`CHM|`).
  * **Tier 3 — Partial / Appearance Only (KDE Plasma, Cinnamon, MATE):** Cursors, 4K wallpapers, and GTK application stylesheets install cleanly; shell-specific components are skipped gracefully.

---

## 9. Running Inside Virtual Machines (VirtualBox, VMware, KVM)

macKali runs completely inside virtualized environments. Because it operates entirely on FreeDesktop and GNOME standards without bare-metal hardware dependencies, it is fully compatible with VirtualBox, VMware Workstation, and QEMU/KVM.

### VirtualBox Performance Configuration
1. **Enable 3D Acceleration:** In VirtualBox, go to **Settings &rarr; Display**, check **"Enable 3D Acceleration"**, and allocate **128 MB or 256 MB VRAM**. Without 3D acceleration, GNOME falls back to software rendering (`llvmpipe`), causing window transitions and dock effects to stutter.
2. **Install Guest Additions:** Ensure guest integration is active for auto-resizing and smooth vector cursor rendering:
   ```bash
   sudo apt update && sudo apt install -y virtualbox-guest-x11
   ```
3. **Recommended Presets for VMs:**
   * **Balanced Preset (`./install.sh --preset balanced`):** Default recommendation for modern VMs (4GB+ RAM, 2-4 vCPUs).
   * **Minimal Preset (`./install.sh --preset minimal`):** Best for low-resource VMs (2-4GB RAM). Delivers the complete macOS dark/light interface, circular traffic lights, and WhiteSur cursors with zero extension overhead.
   * *Avoid 3D physics effects (`--with-cube` or `--with-wobbly`) inside VirtualBox unless PCI GPU passthrough is enabled.*
4. **Theming the VirtualBox Manager App:** If you run the VirtualBox GUI application inside macKali, run `./scripts/providers/qt-provider.sh --install` to style its interior panels with the WhiteSur Qt/Kvantum theme.

---

## 10. Security Architecture, Integrity Auditing & Stealth Mode

macKali contains **zero telemetry, zero tracking, zero background daemons, and zero credential scrapers**. It operates rootless in user space. However, on monitored enterprise networks, penetration test jumpboxes, or air-gapped environments, the following 5 behaviors are transparently documented:

1. **Outbound GitHub Release Check:** By default, `./install.sh` issues an HTTP GET request to `https://api.github.com/repos/realmadede/macKali/releases/latest` with a 2-second timeout to alert you if an update is available.
   * *Stealth Override:* Pass `--no-update-check` to disable all network calls.
2. **Environment Configuration (`~/.config/environment.d/`):** The Qt provider writes `10-mackali-qt.conf` setting `QT_STYLE_OVERRIDE=kvantum` and `QT_QPA_PLATFORMTHEME=qt5ct`. Endpoint Detection & Response (EDR) or auditd tools monitoring `environment.d` will observe this user configuration write.
3. **User GTK Stylesheet Injection:** Styles are appended to `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` between clear marker comments. File Integrity Monitors (FIM) like AIDE or OSSEC will report modified timestamps on these two files.
4. **D-Bus GSettings Desktop Calls:** Window control order (`close,minimize,maximize:`) and Dash to Dock positions are applied via standard GSettings over the user D-Bus session.
5. **Nautilus Process Refresh:** When switching themes, macKali may issue `nautilus -q` to refresh GNOME CSS stylesheets immediately without requiring a full logout. Process monitors will log a file manager termination and respawn event.

### Total Stealth / Air-Gapped Installation
For air-gapped or strictly monitored security environments:
```bash
./install.sh --preset minimal --no-update-check
```

---

For full disaster recovery steps and manual commands, see [docs/safety-and-removal.md](safety-and-removal.md).
