# scripts/path_a/ - LibreLane Flow Automation

This folder contains the execution scripts for **Part A (LibreLane Flow)**.

---

## Files in this Directory

### 1. `install_path_a.sh`
- **What it does**: 
  1. Installs host-side simulation and verification tools that are not provided inside the LibreLane environment (`iverilog`, `verilator`, `gtkwave`, `ngspice`, `python3`, `cocotb`, `pyuvm`, `make`, `git`, `docker`, and optional `gh`).
  2. Sets up an isolated Python virtual environment at `~/.eda_venv`.
  3. Installs **LibreLane** and the **Ciel** PDK manager.
  4. Downloads and enables the SkyWater 130nm PDK (`sky130A`).
  5. Executes the official LibreLane `--smoke_test`.
  6. Automatically runs the sample cocotb testbench in `examples/cocotb_test`.
- **Options**:
  - `--nix`: Uses the FOSSi Foundation Determinate Systems Nix installation route instead of Docker.
  - `--dry-run`: Previews actions without modifying the system.
  - `--yes`: Skips confirmation prompts.

### 2. `run_counter.sh`
- **What it does**: 
  - Activates the `~/.eda_venv` environment.
  - Invokes `librelane --dockerized` on the synthesizable 4-bit synchronous counter design located in `examples/counter`.
  - Places final synthesis reports, timing checks, and GDSII layouts in `examples/counter/runs/`.

---

## Direct Invocation
```bash
# Run Part A installer
./scripts/path_a/install_path_a.sh

# Run example counter flow
./scripts/path_a/run_counter.sh
```
