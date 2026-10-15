# macKali Testing Suite

This directory contains automated test suites and validation procedures to verify that all scripts, manifests, and commands execute properly and safely without destructive side-effects.

---

## Quick Run

Execute the automated test suite from the repository root:

```bash
./tests/run-tests.sh
```

---

## Test Coverage

| Test | Method | Description |
| :--- | :--- | :--- |
| **1. Shell Syntax** | `bash -n <script>` | Validates syntax of all 10 bash scripts without executing them. |
| **2. JSON Validation** | `python3 -m json` | Ensures all manifest and preset JSON files have valid syntax. |
| **3. Schema Compliance** | Schema assertion | Ensures all 5 extension manifests comply with `manifest-schema.json`. |
| **4. CLI Arguments** | `--help` flags | Verifies argument parsing, usage text, and exit code `0`. |
| **5. Compatibility Check** | Non-destructive execution | Verifies OS detection, GNOME version extraction, and matrix matching. |
| **6. Dry-Run Installer** | `--dry-run` | Verifies preset resolution and output reporting across all presets. |
| **7. Backup & Restore** | Isolated `/tmp` sandbox | Creates real dconf backups in a sandbox and tests restoration. |
| **8. Cursor Lifecycle** | Local install/uninstall | Tests installation to `~/.local/share/icons` and verifies clean removal. |

---

## How to Test Commands Manually

If you want to manually verify commands one by one:

### 1. Test Environment Detection (No System Changes)
```bash
./scripts/compat-check.sh
# Expected: Displays Kali Linux OS, GNOME Shell version, and extension support.
```

### 2. Test Installer in Simulation Mode (No System Changes)
```bash
./scripts/install.sh --preset balanced --dry-run
# Expected: Prints preset components and preview actions without modifying anything.
```

### 3. Test Isolated Backup (Safe Directory)
```bash
./scripts/backup.sh --dest /tmp/test-backup
# Expected: Generates backup-meta.json and dconf files in /tmp/test-backup.
```

### 4. Test Cursor Installation & Removal
```bash
# Install to user directory:
./themes/cursors/install.sh
ls ~/.local/share/icons/WhiteSur-cursors/cursors  # Check files exist

# Remove cleanly:
./themes/cursors/install.sh --uninstall
ls ~/.local/share/icons/WhiteSur-cursors          # Check directory is gone
```
