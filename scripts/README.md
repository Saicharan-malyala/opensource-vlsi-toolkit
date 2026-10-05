# scripts/ - Modular Automation Architecture

This directory houses all modular automation scripts organized into specialized functional subdirectories.

---

## Subdirectories

### 1. `path_a/`
- Contains the orchestration scripts for **Part A: LibreLane Flow**.
- Installs the LibreLane orchestration tool inside an isolated virtual environment (`~/.eda_venv`), downloads the SkyWater 130nm PDK via `ciel`, and installs host-only simulation tools.
- Includes `run_counter.sh` to execute the example 4-bit synchronous counter through LibreLane.

### 2. `path_b/`
- Contains the orchestration scripts for **Part B: IIC-OSIC-TOOLS**.
- Clones upstream launcher scripts from JKU Linz, checks free disk space (minimum 20 GB), pulls `hpretl/iic-osic-tools:latest`, and performs container gap-checking.

### 3. `tools/`
- Reusable, idempotent installer blocks for every individual tool in scope (Yosys, Icarus Verilog, Verilator, GTKWave, Docker, LibreLane, OpenROAD, Magic, Netgen, KLayout, Ciel/Sky130, OpenSTA, ngspice, cocotb, pyuvm, Make, Git, GitHub CLI, and Xschem).
- These scripts are modular building blocks called by `install_all.sh`, Part A host setups, and Part B gap-fillers.

### 4. `optional/`
- Helper scripts for optional developer setup tasks, including `github_setup.sh` to configure global Git user identities and GitHub CLI authentication.

### 5. `wsl/`
- Contains Windows PowerShell automation scripts (`wsl_setup.ps1`) for preparing Windows 10/11 machines with WSL2, Ubuntu, Docker Desktop, memory limits (`.wslconfig`), and running the Linux installer.

---

## Common CLI Flags Supported By All Scripts
- `--dry-run`: Preview all shell commands without modifying your system.
- `--yes`: Skip interactive `[y/N]` confirmation prompts.
- `--help`: Display usage summary.
