# Contributing to macKali

Thank you for your interest in contributing to **macKali**! This document outlines the development workflow, safety requirements, branch architecture, and coding standards required for all contributions.

---

## 1. Critical Host Safety Rules

Because **macKali** modifies GNOME Shell, GTK3/GTK4, Qt/Kvantum, and `dconf` appearance settings, contributors must follow strict safety rules when developing and testing:

1. **Zero Root Privilege (`sudo` Prohibited)**:
   - macKali is a **100% rootless** user-space customization suite.
   - Never introduce `sudo`, `pkexec`, `su`, `apt`, `dpkg`, or system-wide `/usr/share` writes into any macKali script.
2. **Never Run Untested Changes Against Your Live Host Session**:
   - Always run the automated test suite first (`./tests/run-tests.sh`), which uses isolated temporary `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and mocked/sandboxed `dconf`/`gsettings` environments.
   - For live graphical verification, use a **disposable Kali Linux GNOME virtual machine** with a recovery snapshot.
3. **Preserve User Configuration & Safe Rollback**:
   - Every setting modified by macKali must be recorded in the user's backup snapshot (`scripts/backup.sh`) or appearance snapshot (`scripts/appearance.sh`).
   - Any new setting or file modification must have a corresponding, scoped reversal in [`scripts/uninstall.sh`](scripts/uninstall.sh) and [`scripts/restore.sh`](scripts/restore.sh) that never deletes unrelated user customizations.

---

## 2. Branch Architecture (`main` vs. `website`)

macKali strictly separates its desktop customization suite from its static showcase website:

- **`main` Branch**: Contains the desktop customization suite (`install.sh`, `scripts/`, `themes/`, `config/`, `extensions/`, `docs/`, `tests/`).
  - **Never** commit `website/` files to the `main` branch (`/website` is ignored on `main`).
- **`website` Branch**: Contains the static documentation & showcase portal (`website/index.html`, `website/styles.css`, `website/script.js`, `website/build.sh`).
  - All website changes must be submitted exclusively against the `website` branch and verified with `bash website/build.sh --clean`.

---

## 3. Development & Testing Workflow

### Prerequisites
- `bash` (4.0+)
- `python3` (3.8+)
- `jq`, `dconf-cli`, `libglib2.0-bin` (`gsettings`), `dbus-x11` (`dbus-run-session`)

### Running the Isolated Test Suite
Before opening a Pull Request on `main`, run the full verification suite:

```bash
# 1. Verify Bash syntax across all scripts
bash -n install.sh build.sh scripts/*.sh scripts/lib/*.sh scripts/providers/*.sh themes/cursors/*.sh tests/*.sh

# 2. Run the isolated 69-test suite
./tests/run-tests.sh

# 3. Verify dry-run and CLI entry points
./install.sh --help
./install.sh --check
./install.sh --dry-run --no-update-check
```

### Verifying Release Packaging
If your change adds new required assets, scripts, or documentation files, verify that standalone release packaging succeeds:

```bash
./scripts/package-release.sh --output-dir /tmp/mackali-test-dist
rm -rf /tmp/mackali-test-dist
```

---

## 4. Coding Standards

- **Strict Mode**: All Bash scripts must begin with:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- **ShellCheck Compliance**: Avoid unquoted variables, non-POSIX pitfalls where applicable, and handle `# shellcheck disable=SC1091` annotations cleanly when sourcing `scripts/lib/common.sh`.
- **Idempotency**: Running an installer or provider twice in a row must produce the exact same state without duplicating CSS blocks or corrupting baseline backups.
- **Wayland & X11 Compatibility**: Never force X11/XCB overrides (such as unconditional `QT_QPA_PLATFORM=xcb`) on GNOME Wayland sessions.
- **GNOME Version Agnosticism**: Do not hardcode a single GNOME version. Use the dynamic 4-tier compatibility evaluator in [`scripts/compat-check.sh`](scripts/compat-check.sh) and [`scripts/extensions-manager.sh`](scripts/extensions-manager.sh).

---

## 5. Submitting a Pull Request

1. Fork the repository and create a feature or bugfix branch from `main` (or `website` for portal changes).
2. Ensure all automated tests (`./tests/run-tests.sh`) pass with `0` failures.
3. Follow Conventional Commit messages (e.g., `feat(appearance): ...`, `fix(qt-provider): ...`, `docs(readme): ...`).
4. Complete the Pull Request checklist in `.github/PULL_REQUEST_TEMPLATE.md`.
