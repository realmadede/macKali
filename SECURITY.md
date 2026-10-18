# Security Policy

## Supported Versions

The **macKali** project provides security updates and maintenance for the following versions:

| Version | Status | Supported |
| :--- | :--- | :---: |
| `v1.0.x` (Stable) | Active Stable Release | ✅ Yes |
| `v1.0.0-rc.1` | Historical Release Candidate | ❌ No (Upgrade to `v1.0.0+`) |
| `< v1.0.0` | Pre-release / Development | ❌ No |

---

## Security Model & Design Guarantees

macKali is designed specifically for **Kali Linux GNOME** users and adheres to strict user-space security boundaries:

1. **100% Rootless Execution**:
   - macKali never invokes `sudo`, `su`, `pkexec`, `apt`, or `dpkg`.
   - All themes, icons, cursors, extensions, and configuration files are written strictly within the active user's home directory (`~/.config`, `~/.local/share`, `~/.themes`, `~/.icons`).
2. **Cryptographic Release Verification**:
   - Every official GitHub Release (`macKali-v<VERSION>.tar.gz`) is accompanied by a `SHA256SUMS` manifest generated in CI so users can verify archive integrity before extraction:
     ```bash
     sha256sum -c SHA256SUMS
     ```
3. **No Arbitrary Remote Code Execution**:
   - The in-app update checker (`./install.sh --check-update`) queries the GitHub Releases API read-only over HTTPS and never downloads or executes remote scripts automatically.
   - Optional upstream theme/icon providers (`WhiteSur-gtk-theme`, `WhiteSur-icon-theme`) are opt-in (`--install-upstream`) and can be skipped entirely in offline/air-gapped environments.

---

## Reporting a Vulnerability

If you discover a security issue in macKali—such as command injection, unsafe path traversal, symlink vulnerabilities in backup/restore handling, or unintended privilege escalation—**please do not open a public GitHub issue**.

Instead, report it privately using one of the following methods:

1. **GitHub Private Vulnerability Reporting (Preferred)**:
   - Navigate to the **[Security Advisories](https://github.com/realmadede/macKali/security/advisories/new)** page of the `realmadede/macKali` repository and submit a private report.
2. **What to Include in Your Report**:
   - A clear description of the vulnerability and the affected script(s) and line numbers.
   - Step-by-step reproduction instructions in an isolated environment (`--dry-run` or sandboxed `HOME`).
   - Potential impact on a user's Kali Linux GNOME environment.
   - Suggested remediation or patch, if available.

### Response Timeline
- **Initial Acknowledgment**: Within **48–72 hours** of submission.
- **Triage & Fix Verification**: Within **7 days** for confirmed vulnerabilities, followed by a patched point release (`v1.0.x`) and security advisory credit.
