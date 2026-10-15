# macKali Scripts Suite

This directory contains modular automation scripts for system inspection, installation, backup, restoration, and removal.

## Scripts Overview

| Script | Purpose | Privileges |
| :--- | :--- | :--- |
| `install.sh` | Main macKali installer engine; supports presets, dry runs, and cursor deployment | User (elevates only if `--system` requested) |
| `compat-check.sh` | Non-destructive system detection, dependency verification, and extension compatibility checking | User |
| `backup.sh` | Creates timestamped backups of `dconf` desktop/shell databases and theme configurations | User |
| `restore.sh` | Restores previous GNOME desktop settings from a chosen or latest backup archive | User |
| `uninstall.sh` | Safely removes installed assets (`~/.local/share/icons/WhiteSur-cursors`) and optionally reverts settings | User (root for system assets) |
| `lib/common.sh` | Shared shell library for formatted logging, OS detection, and GNOME Shell version inspection | Library |

## Usage Examples

### 1. Check System Compatibility
```bash
./scripts/compat-check.sh
```

### 2. Create a Timestamped Backup
```bash
./scripts/backup.sh
```

### 3. Run Dry-Run Installation
```bash
./scripts/install.sh --preset balanced --dry-run
```

### 4. Restore Settings from Backup
```bash
# Restore latest backup:
./scripts/restore.sh

# List available backups:
./scripts/restore.sh --list

# Restore specific backup:
./scripts/restore.sh --from ~/.config/macKali/backups/20261015_120000
```

### 5. Uninstall Assets
```bash
./scripts/uninstall.sh --restore-settings
```
