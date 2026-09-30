#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/cocotb.sh - Install and Verify cocotb and pyuvm
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="cocotb_pyuvm"
COCOTB_PIN="${COCOTB_VERSION:-1.9.2}"
PYUVM_PIN="${PYUVM_VERSION:-0.3.4}"
EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"

log_step "Checking ${TOOL_NAME} inside python environment..."

# Ensure python & venv exist first
"${SCRIPT_DIR}/scripts/tools/python.sh"

setup_venv() {
    if [[ ! -d "${EDA_VENV}" ]]; then
        log_info "Creating central EDA python venv at ${EDA_VENV}..."
        run_cmd python3 -m venv "${EDA_VENV}"
    fi
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[DRY-RUN] Simulating venv activation and pip installs."
        return 0
    fi
    if [[ -f "${EDA_VENV}/bin/activate" ]]; then
        # shellcheck disable=SC1091
        source "${EDA_VENV}/bin/activate"
        run_cmd pip install --upgrade pip
    fi
}

check_installed() {
    if [[ -d "${EDA_VENV}" ]]; then
        # shellcheck disable=SC1091
        source "${EDA_VENV}/bin/activate"
        if python -c 'import cocotb, pyuvm; print("ok")' >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

if check_installed; then
    CV=$(python -c 'import cocotb; print(cocotb.__version__)')
    PV=$(python -c 'import pyuvm; print(pyuvm.__version__)')
    log_info "cocotb (${CV}) and pyuvm (${PV}) already installed in ${EDA_VENV}. Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "cocotb ${CV}, pyuvm ${PV}"
    exit 0
fi

setup_venv
log_info "Installing cocotb==${COCOTB_PIN} and pyuvm==${PYUVM_PIN} in venv..."
run_cmd pip install "cocotb==${COCOTB_PIN}" "pyuvm==${PYUVM_PIN}"

# VERIFY step
log_step "Verifying ${TOOL_NAME}..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME}" "INSTALLED" "dry-run"
    exit 0
fi

if python -c 'import cocotb, pyuvm; print(f"cocotb={cocotb.__version__}, pyuvm={pyuvm.__version__}")' >/dev/null 2>&1; then
    CV=$(python -c 'import cocotb; print(cocotb.__version__)')
    PV=$(python -c 'import pyuvm; print(pyuvm.__version__)')
    log_success "Verified cocotb v${CV} and pyuvm v${PV} in virtual environment."
    record_summary "${TOOL_NAME}" "INSTALLED" "cocotb ${CV}, pyuvm ${PV}"
else
    log_error "Failed to verify cocotb and pyuvm."
    record_summary "${TOOL_NAME}" "FAILED" "Import failed"
    exit 1
fi
