---
name: Bug Report
about: Report a bug in macKali's installer, appearance providers, extensions, or uninstallation
title: "[BUG] "
labels: bug
assignees: realmadede
---

## Bug Description
A clear and concise description of what the bug is.

## Steps to Reproduce
1. Run command `...`
2. Select option / preset `...`
3. Observe error or unexpected behavior `...`

## Expected Behavior
A clear description of what you expected to happen.

## Environment Diagnostics
Please provide the output of the following commands on your system:

- **macKali Version** (`cat VERSION` or `./install.sh --version`):
- **Kali Linux Version** (`grep PRETTY_NAME /etc/os-release`):
- **GNOME Shell Version** (`gnome-shell --version`):
- **Display Session Type** (`echo $XDG_SESSION_TYPE` — Wayland or X11):
- **Selected Preset** (`minimal` / `balanced` / `full`):

### Compatibility Report Output
Please paste the output of `./scripts/compat-check.sh`:
```text
Paste ./scripts/compat-check.sh output here
```

## Additional Context / Logs
Add any terminal output, dry-run output (`./install.sh --dry-run`), or screenshots that help explain the problem.
