# Safety Guarantees, Risk Assessment & Complete Removal

This document provides transparent information on how **macKali** interacts with your system, the realistic risks involved, how to prevent issues, and how to **completely remove it** without leaving any trace behind.

---

## 1. Can macKali Disrupt or Break My Kali Machine?

### Short Answer
**No, macKali cannot break your Kali Linux operating system, kernel, or security tools.**

### Detailed Technical Breakdown

| Component | Does macKali Modify It? | Details |
| :--- | :---: | :--- |
| **Kali Security & Pentest Tools** | **NO** | Tools like Nmap, Wireshark, Metasploit, Burp Suite, Aircrack, etc. are completely untouched. |
| **System Libraries & Kernel** | **NO** | macKali does not modify `/usr/lib`, `/etc/`, kernel modules, or systemd services. |
| **APT Repositories & Packages** | **NO** | macKali does not alter `/etc/apt/sources.list` or add unverified PPAs. |
| **Networking & Firewall** | **NO** | No network configurations, proxies, or firewall rules are altered. |
| **Root Privileges** | **NO** | macKali operates entirely within the user space. Root (`sudo`) is never required unless you explicitly request system-wide installation. |
| **User Data & Home Directory** | **NO** | Personal documents, downloads, and workspaces are completely untouched. |
| **GNOME User Settings (`dconf`)** | **YES** | Desktop theme names, cursor sizes, and button layouts are configured in the user's `dconf` database (always backed up prior to modification). |
| **User Theme Folders** | **YES** | Cursors are placed in `~/.local/share/icons/WhiteSur-cursors`. |

---

## 2. Realistic Risks & How They Are Mitigated

Even though macKali cannot destroy your OS, desktop customization carries practical considerations:

### Risk 1: Desktop Environment Mismatch (XFCE vs GNOME)
- **The Issue**: Many default Kali Linux installations use **XFCE** instead of **GNOME**. macKali is built specifically for GNOME. Running GNOME `dconf` commands on XFCE will not customize the desktop and can cause confusion.
- **The Fix**: macKali's [`scripts/compat-check.sh`](../scripts/compat-check.sh) inspects `$XDG_CURRENT_DESKTOP`. If you are on XFCE, it alerts you and explains how to install or switch to GNOME safely (`sudo apt install kali-desktop-gnome`).

### Risk 2: Kali Rolling Release & Extension Breakage
- **The Issue**: Kali is a rolling distribution. When GNOME Shell updates to a new major version (e.g., GNOME 47 to 50), third-party extensions might temporarily lag behind and disable themselves.
- **The Fix**: 
  - macKali **never** disables GNOME version validation flags.
  - Manifests track verified GNOME versions.
  - If an extension fails to load after a system upgrade, simply disable it with `gnome-extensions disable <UUID>`.

### Risk 3: Window Controls Muscle Memory
- **The Issue**: macOS positions traffic-light window controls (Close, Minimize, Maximize) on the top-left, whereas default Kali Linux places them on the top-right.
- **The Fix**: You can easily toggle or revert this single setting at any time without uninstalling:
  ```bash
  gsettings reset org.gnome.desktop.wm.preferences button-layout
  ```

---

## 3. How to Test macKali Safely Before Installing (Zero-Risk Evaluation)

If you want to evaluate macKali without risking your main Kali Linux desktop, you can test it progressively using four safe methods:

### Tier 1: Zero-Touch Preview & Simulation (`--check`, `--dry-run`, `--preview`)
macKali includes built-in read-only flags that inspect your system and print every action that *would* be taken without modifying any files or `dconf` settings:

```bash
# 1. Verify GNOME version, Wayland/X11 session, and required utilities:
./install.sh --check

# 2. Simulate a full or minimal installation (creates zero files and zero backups):
./install.sh --dry-run --full
./install.sh --dry-run --minimal

# 3. Walk through the interactive wizard in dry-run mode:
./install.sh --interactive --dry-run

# 4. Preview window button layout and GTK3/GTK4 CSS paths only:
./scripts/appearance.sh --preview
```

### Tier 2: Isolated Directory Sandbox (Temporary `HOME`)
Because macKali runs entirely in user space (`~/.config` and `~/.local/share`) and never requires `sudo`, you can run the automated test suite or inspect generated configuration files inside a temporary `/tmp` sandbox:

```bash
# Run the 69-test isolated verification suite (uses mocked gsettings/dconf):
./tests/run-tests.sh

# Or simulate a dry-run inside a disposable temporary HOME directory:
SANDBOX=$(mktemp -d)
HOME="$SANDBOX" XDG_CONFIG_HOME="$SANDBOX/.config" XDG_DATA_HOME="$SANDBOX/.local/share" \
  ./install.sh --dry-run --full
rm -rf "$SANDBOX"
```

### Tier 3: Disposable Linux User Account (Live GNOME Preview)
Because macKali only modifies user-level configuration files and user `dconf` keys—never system-wide `/usr/share` or `/etc` files—you can test the full live visual experience in a secondary Linux user account:

1. Create a temporary test user account (e.g., `mackali-test`) in GNOME Settings → Users.
2. Log into the `mackali-test` GNOME session and run `./install.sh --minimal` or `./install.sh --interactive`.
3. Your primary user account's `~/.config`, themes, extensions, and GNOME settings remain **100% untouched**. Delete the temporary user account when finished.

### Tier 4: Virtual Machine Snapshot (Full Compositor & Extension Test)
To test everything—including 3D GNOME extensions, Kvantum/Qt application styling, and session logouts—with instant rollback:

1. Boot a Kali Linux VirtualBox, VMware, or QEMU/KVM virtual machine and **take a VM snapshot**.
2. Run `./install.sh --interactive` inside the VM to test the desktop and `./scripts/uninstall.sh`.
3. Revert the VM snapshot in one click when finished.

---

## 4. How to Remove macKali Safely (Scoped Reversal vs. Full Restore)

We believe in complete user transparency. macKali distinguishes between **reversing macKali-managed changes** and **restoring an entire desktop snapshot**:

### Option A: Default Scoped Uninstallation (Recommended for Everyday Removal)
Running `scripts/uninstall.sh` without destructive flags reverses **only** the files and settings managed by macKali (removing WhiteSur cursors, wallpapers, tracked theme assets, and reverting macKali's window button / appearance / extension state) while preserving any unrelated desktop settings or custom GTK/Qt configurations you modified after installing macKali:

```bash
./scripts/uninstall.sh
```

### Option B: Restore Full Desktop Snapshot (`--restore-backup`)
If you want to restore the entire `dconf` desktop/shell/extensions snapshot captured by `scripts/backup.sh` prior to installation (note: this restores the complete point-in-time `dconf` tree from the backup archive):

```bash
./scripts/restore.sh
# or during uninstallation:
./scripts/uninstall.sh --restore-backup
```

### Option C: The One-Command Nuclear Purge (`--purge`)
This removes all installed assets, resets modified GNOME settings back to stock Kali Linux system defaults, and deletes `~/.config/macKali` backup caches:

```bash
./scripts/uninstall.sh --purge
# or
./install.sh --purge
```

### Option D: 100% Manual Removal (No Scripts Required)
If you do not want to execute any macKali script to remove it, run these four native Linux commands in your terminal:

```bash
# 1. Reset cursor theme to Kali default (Adwaita)
gsettings reset org.gnome.desktop.interface cursor-theme
gsettings reset org.gnome.desktop.interface cursor-size

# 2. Reset window button layout back to Kali default (Right side)
gsettings reset org.gnome.desktop.wm.preferences button-layout

# 3. Delete the installed WhiteSur cursor directory
rm -rf ~/.local/share/icons/WhiteSur-cursors

# 4. Remove macKali backups and configuration cache
rm -rf ~/.config/macKali
```

Once executed, your desktop will immediately return to standard Kali Linux defaults, with zero remnants left on your computer.

---

## 5. Emergency Recovery: What If GNOME Shell Freezes?

In the unlikely event that a combination of extensions causes GNOME Shell to freeze under Wayland:

1. Switch to a virtual terminal: Press `Ctrl + Alt + F3`.
2. Log in with your Kali username and password.
3. Choose the appropriate recovery action:

   **Option 1: Safely restore macKali extensions and dock settings (Preserves other user extensions)**:
   ```bash
   cd ~/BAGOMWA/PROJECTS/macKali  # or your repository path
   ./scripts/extensions-manager.sh --restore
   ```
   Or manually disable only macKali-managed extensions:
   ```bash
   for ext in dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx compiz-alike-magic-lamp-effect@hermes83.github.com compiz-windows-effect@hermes83.github.com desktop-cube@schneegans.github.com; do
     gnome-extensions disable "$ext" 2>/dev/null || true
   done
   ```

   **Option 2: Instantly disable all user extensions globally (Built-in GNOME setting)**:
   ```bash
   gsettings set org.gnome.shell disable-user-extensions true
   ```
   *(To re-enable user extensions once logged back in: `gsettings set org.gnome.shell disable-user-extensions false`)*

4. Revert window controls if needed:
   ```bash
   gsettings reset org.gnome.desktop.wm.preferences button-layout
   gsettings reset org.gnome.desktop.interface cursor-theme
   ```
5. Switch back to your graphical desktop: Press `Ctrl + Alt + F2` (or `Ctrl + Alt + F1`).

---

## 6. Security Transparency: Monitored Environments & Stealth Mode

macKali is designed for security professionals and ethical hackers. To assist security audits, File Integrity Monitoring (FIM), and Endpoint Detection (EDR), all background interactions are listed below:

| Interaction | Purpose | Impact & How to Audit |
| :--- | :--- | :--- |
| **GitHub Release API Query** | Checks for official version updates via `https://api.github.com/` (2s timeout). | Outbound HTTP GET. Disable with `--no-update-check`. |
| **`~/.config/environment.d/`** | Configures Qt & Kvantum WhiteSur theming environment variables. | User configuration file `10-mackali-qt.conf`. Safe to inspect or delete. |
| **`~/.config/gtk-*.0/gtk.css`** | Injects circular traffic light CSS rules between delimited comment markers. | Appends user CSS. Never modifies unrelated custom CSS. |
| **D-Bus GSettings Calls** | Sets window button layout and dock layout. | Standard user D-Bus calls. No root escalation. |
| **Nautilus Process Refresh** | Issues `nautilus -q` to reload GTK CSS without requiring user logout. | Safe process restart for instantaneous styling application. |

**Stealth / Air-Gapped Flag:**
```bash
./install.sh --preset minimal --no-update-check
```
