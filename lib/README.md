# lib/ - Shared Script Libraries & Common Utilities

This directory contains the core reusable shell library used across all automated installer scripts in this repository.

---

## Files in this Directory

### `common.sh`
- **Purpose**: Centralized functions, environment sanitization, and output formatters for all bash scripts.
- **Key Features**:
  1. **Safe Shell Configuration**: Enforces `set -euo pipefail` to catch errors early.
  2. **ANSI Color Logging**: Formatted `log_info`, `log_success`, `log_warn`, `log_error`, and `log_step` messages.
  3. **Execution Logging**: Automatically captures command invocations and outputs to session logs in `../logs/`.
  4. **Dry-Run Wrapper (`run_cmd`)**: Intercepts commands when `--dry-run` is active and prints what would be run without changing the host system.
  5. **Sudo Prompt Management (`request_sudo`)**: Checks for root privileges, explains why `sudo` is required, and requests user confirmation with `[y/N]` (or skips when `--yes` is supplied). Scripts are never run entirely as root.
  6. **Distro Package Manager Detection (`detect_pkg_mgr`)**: Identifies `apt`, `dnf`, `pacman`, or `zypper`.
  7. **Fallback Notification (`notify_unsupported_tool`)**: If a package manager cannot provide a tool, prints a formatted notification referencing the exact section of `README_MANUAL_INSTALL.md` and marks the item `SKIPPED` in the summary rather than terminating the run.
  8. **Semantic Version Comparison (`version_gte`)**: Evaluates installed versions against minimum required baselines.
  9. **Summary Table Tracker**: Generates clean, terminal-rendered markdown status tables at the conclusion of script runs.

---

## How It Is Used
Internal installer scripts source this file via:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
```
