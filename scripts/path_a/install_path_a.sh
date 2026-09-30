#!/usr/bin/env bash
# ==============================================================================
# scripts/path_a/install_path_a.sh - Part A Orchestrator (LibreLane + Host Tools)
# ==============================================================================
# Installs:
# 1. Host tools that the LibreLane environment does not provide:
#    - git, make, python3 (with venv & tkinter), docker, iverilog, verilator,
#      gtkwave, ngspice, cocotb, pyuvm, and optional gh.
# 2. LibreLane inside dedicated python venv (~/.eda_venv)
# 3. Ciel PDK manager and downloads default Sky130 PDK
# 4. Runs smoke tests and the counter example verification
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

USE_NIX=0
for arg in "$@"; do
    case "${arg}" in
        --nix) USE_NIX=1 ;;
        --dry-run) export DRY_RUN=1 ;;
        --yes) export ASSUME_YES=1 ;;
        --help)
            echo "Usage: ./scripts/path_a/install_path_a.sh [--nix] [--dry-run] [--yes] [--help]"
            exit 0
            ;;
    esac
done

log_step "Starting Part A (LibreLane Flow Setup)..."

# 1. Install Host Prerequisites
log_info "Step 1/4: Installing Host Tools (RTL simulation, verification, and utilities)..."
"${SCRIPT_DIR}/scripts/tools/git.sh"
"${SCRIPT_DIR}/scripts/tools/make.sh"
"${SCRIPT_DIR}/scripts/tools/python.sh"
"${SCRIPT_DIR}/scripts/tools/docker.sh"
"${SCRIPT_DIR}/scripts/tools/iverilog.sh"
"${SCRIPT_DIR}/scripts/tools/verilator.sh"
"${SCRIPT_DIR}/scripts/tools/gtkwave.sh"
"${SCRIPT_DIR}/scripts/tools/ngspice.sh"
"${SCRIPT_DIR}/scripts/tools/cocotb.sh"
"${SCRIPT_DIR}/scripts/tools/gh.sh"

if [[ "${USE_NIX}" -eq 1 ]]; then
    log_info "Nix route selected: Installing via Determinate Systems Nix installer..."
    if ! command -v nix >/dev/null 2>&1; then
        run_cmd curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    fi
    log_info "Nix installation prepared."
fi

# 2. Install LibreLane & Ciel
log_info "Step 2/4: Installing LibreLane ASIC Flow & Ciel PDK Manager..."
"${SCRIPT_DIR}/scripts/tools/librelane.sh"

# 3. Run Tiny Verification Tests
log_info "Step 3/4: Verifying RTL Simulation and Cocotb Test..."
EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"
if [[ -f "${EDA_VENV}/bin/activate" && "${DRY_RUN}" -eq 0 ]]; then
    # shellcheck disable=SC1091
    source "${EDA_VENV}/bin/activate"
    if command -v iverilog >/dev/null 2>&1 && command -v cocotb-config >/dev/null 2>&1; then
        log_info "Running cocotb test in examples/cocotb_test..."
        (cd "${SCRIPT_DIR}/examples/cocotb_test" && make clean && make) || {
            log_warn "Cocotb verification test returned non-zero. Check log for details."
        }
    fi
fi

# 4. Summary Table
print_summary_table
log_success "Part A setup completed!"
