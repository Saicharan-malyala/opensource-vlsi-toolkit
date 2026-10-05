# scripts/tools/ - Individual Tool Automation Blocks

This folder contains idempotent, standalone installer scripts for every individual tool in the EDA scope.

---

## Design Principles
1. **Idempotence**: Every script inspects whether the tool is already present on the system (and meets minimum version criteria) before attempting an install. If present, it skips cleanly.
2. **Package Manager Agnostic**: Detects `apt`, `dnf`, `pacman`, or `zypper`. If a tool cannot be installed on a given distribution, the script prints an actionable notice pointing to the relevant section of `README_MANUAL_INSTALL.md` and marks the tool `SKIPPED` in the final summary.
3. **Dedicated Virtual Environment**: Python-based tools (`cocotb`, `pyuvm`, `librelane`, `ciel`) install cleanly into a central virtual environment (`~/.eda_venv`) to prevent `externally-managed-environment` errors on modern distributions (Debian 12+, Ubuntu 23.04+, Fedora 38+).
4. **Verification Step**: Every installer terminates with a functional execution test (e.g. running a test simulation, synthesis parse, or command invocation).

---

## File Catalog

| Script | Tool Name | Scope & Function |
| :--- | :--- | :--- |
| `git.sh` | Git | Distributed version control; checks minimum version `2.35.0` |
| `make.sh` | GNU Make | Build automation; verifies with a mock Makefile target |
| `python.sh` | Python 3 | Installs Python 3 runtime, pip, venv, and Tkinter GUI bindings |
| `docker.sh` | Docker Engine / Podman | Installs container runtime, adds user to `docker` group, supports `--podman` |
| `iverilog.sh` | Icarus Verilog | Verilog simulation compiler; verifies by executing a simulation test |
| `verilator.sh` | Verilator | C++ hardware compiler & linter; verifies with a syntax check |
| `gtkwave.sh` | GTKWave | Graphical waveform viewer for simulation traces |
| `ngspice.sh` | ngspice | SPICE circuit simulator; verifies with a batch RC circuit simulation |
| `cocotb.sh` | cocotb & pyuvm | Coroutine Python testbench and verification framework |
| `librelane.sh` | LibreLane | Modern digital ASIC flow pipeline; verifies via `--smoke_test` |
| `ciel.sh` | Ciel & Sky130 PDK | FOSSi Foundation PDK package manager; manages `~/.ciel/sky130A` |
| `yosys.sh` | Yosys | Verilog RTL synthesis engine; verifies with a gate synthesis run |
| `openroad.sh` | OpenROAD | Autonomous physical design tool; supports official prebuilt `.deb` releases |
| `opensta.sh` | OpenSTA | Static timing analysis engine |
| `magic.sh` | Magic VLSI | Layout editor, DRC, and GDS extraction tool |
| `netgen.sh` | Netgen | Netlist comparison and Layout Versus Schematic (LVS) tool |
| `klayout.sh` | KLayout | High-performance GDSII/OASIS mask layout viewer |
| `xschem.sh` | Xschem | Schematic capture tool (optional) |
| `gh.sh` | GitHub CLI | Official GitHub command-line interface (optional) |
