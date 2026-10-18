## Summary
Briefly describe the changes introduced in this Pull Request and the issue(s) it resolves.

Fixes #(issue_number)

## Target Branch Verification
- [ ] **`main` branch**: Desktop customization scripts, themes, configs, tests, or documentation (contains **no** `website/` files).
- [ ] **`website` branch**: Static showcase website files only (`website/`).

## Safety & Quality Checklist
- [ ] **100% Rootless**: No `sudo`, `su`, `pkexec`, `apt`, or `dpkg` commands were added.
- [ ] **Sandboxed Test Suite Passed**: Ran `./tests/run-tests.sh` locally and all tests pass (`0` failures).
- [ ] **Syntax Verified**: Ran `bash -n` across all modified `.sh` scripts.
- [ ] **Safe Rollback Preserved**: Any new user settings or files are properly backed up and cleanly reversed by `./scripts/uninstall.sh` and `./scripts/restore.sh` without clobbering unrelated user configs.
- [ ] **Wayland & X11 Safe**: No unconditional X11/XCB overrides are forced on GNOME Wayland sessions.
- [ ] **Documentation Updated**: Updated `README.md`, `docs/`, or `CHANGELOG.md` if user-facing CLI flags or behavior changed.

## Test Output
Paste the summary output of `./tests/run-tests.sh`:
```text
Paste test summary output here
```
