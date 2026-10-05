# scripts/optional/ - Developer & GitHub Setup Utilities

This folder contains optional helper scripts for user identity configuration.

---

## Files in this Directory

### `github_setup.sh`
- **What it does**:
  1. Inspects existing global Git configuration (`git config --global user.name` and `git config --global user.email`).
  2. If unset, interactively prompts the user for their name and email for commit attribution.
  3. Checks if the official GitHub CLI (`gh`) is installed and authenticated.
  4. If not logged in, offers to launch `gh auth login` for GitHub authentication.
- **Clarification**:
  - **Git** is the local version control software tool.
  - **GitHub** is the cloud hosting platform service.
  - The GitHub CLI (`gh`) is optional; the EDA flows do not require a GitHub account to run locally.

---

## Direct Invocation
```bash
./scripts/optional/github_setup.sh
```
Supported flags: `--dry-run`, `--yes`.
