# scripts/wsl/ - Windows & WSL2 Automation

This directory contains the Windows-side PowerShell automation script for setting up WSL2 and Ubuntu.

---

## Files in this Directory

### `wsl_setup.ps1`
- **What it does**:
  1. Checks for Windows Administrator privileges.
  2. Verifies Windows OS version and build number (requires Windows 10 Build 19041+ or Windows 11).
  3. Checks if WSL2 is installed; runs `wsl.exe --install -d Ubuntu` if missing and handles reboot guidance.
  4. Explains that the first Ubuntu launch requires creating a UNIX username and password interactively.
  5. Inspects whether Docker Desktop is present on Windows; offers installation via `winget` and reminds the user to enable WSL2 integration for Ubuntu.
  6. Configures `%USERPROFILE%\.wslconfig` with sensible RAM limits (e.g. 8GB/12GB) to prevent Windows host freezing during heavy synthesis runs.
  7. Ensures files are cloned and executed **inside the native Linux filesystem** (`~/eda_tools`), strictly avoiding the slow `/mnt/c/` virtualized mount.
  8. Automatically invokes `install_all.sh` inside Ubuntu through `wsl.exe`.

---

## Direct Usage (from Windows PowerShell as Administrator)
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\scripts\wsl\wsl_setup.ps1 -Path a
```

### Parameters
- `-Path <a|b|manual>`: Specifies which installation path to launch inside WSL (Default: `a`).
- `-DryRun`: Previews all actions without modifying Windows or WSL settings.
- `-Yes`: Automatically confirms prompts.
