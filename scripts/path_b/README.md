# scripts/path_b/ - IIC-OSIC-TOOLS All-In-One Flow Automation

This folder contains the execution scripts for **Part B (IIC-OSIC-TOOLS Container Flow)**.

---

## Files in this Directory

### `install_path_b.sh`
- **What it does**:
  1. Verifies host prerequisites (`git`, `docker`, optional `gh`).
  2. Inspects available storage to ensure at least 20 GB of free disk space is present (the container image is ~4 GB compressed and expands to ~12 GB, plus working design files and PDKs).
  3. Clones the official upstream launcher scripts repository (`https://github.com/iic-jku/IIC-OSIC-TOOLS.git`) into `upstream_iic_osic_tools/` at run time (shallow clone `--depth=1`).
  4. Pulls the official Docker image `hpretl/iic-osic-tools:latest`.
  5. Performs an automated **GAP CHECK** by querying each tool in scope inside the container:
     ```bash
     docker run --rm hpretl/iic-osic-tools:latest bash -lc "command -v <tool>"
     ```
  6. If any tool from the required list is missing inside the container, it calls `scripts/tools/<tool>.sh` to install it on the host as a fallback.
  7. Displays a comprehensive Markdown status table showing each tool's location (Container vs Host) and version.
  8. Explains how to launch the VNC web desktop, local X11 mode, or shell mode.

---

## Direct Invocation
```bash
./scripts/path_b/install_path_b.sh
```
Supported flags: `--dry-run`, `--yes`, `--help`.
