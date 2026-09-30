# examples/ - Verified Hardware Examples & Testbenches

This folder contains verified reference designs used to validate your EDA installation.

---

## Subdirectories

### 1. `counter/`
Contains a synthesizable 4-bit synchronous counter written in Verilog, accompanied by a JSON configuration file for the LibreLane ASIC flow:
- **`counter.v`**: Verilog design with synchronous enable, active-low reset (`rst_n`), and a 4-bit output bus (`count`).
- **`config.json`**: LibreLane digital flow configuration specifying target clock pin (`clk`), clock period (`10.0ns`), core utilization (`40%`), and placement density.

### 2. `cocotb_test/`
Contains a modern Python-based verification testbench using the `cocotb` framework:
- **`test_counter.py`**: Asynchronous coroutine tests checking reset assertion, sequential incrementation, and counter enable/disable hold behavior.
- **`Makefile`**: Standard Cocotb simulation Makefile configured for Icarus Verilog (`SIM=icarus`).

---

## Verification Commands
To test simulation and verification on your host:
```bash
cd examples/cocotb_test
source ~/.eda_venv/bin/activate
make
```
To run the counter through the full LibreLane RTL-to-GDSII flow:
```bash
./scripts/path_a/run_counter.sh
```
