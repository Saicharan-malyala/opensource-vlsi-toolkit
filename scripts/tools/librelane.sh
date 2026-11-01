#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/librelane.sh - Install and Verify LibreLane (Part A Core)
# ==============================================================================
# Installs LibreLane inside a dedicated virtual environment with Docker backend.
# Verifies installation using the official '--smoke_test' flag.
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="librelane"
EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"
LIBRELANE_PIN="${LIBRELANE_VERSION:-3.0.0}"

log_step "Checking ${TOOL_NAME}..."

# Ensure Docker is ready on host
"${SCRIPT_DIR}/scripts/tools/docker.sh"

# Ensure Python & Venv are ready
"${SCRIPT_DIR}/scripts/tools/python.sh"
if [[ ! -d "${EDA_VENV}" ]]; then
    run_cmd python3 -m venv "${EDA_VENV}"
fi
# shellcheck disable=SC1091
source "${EDA_VENV}/bin/activate"

# Check if already installed
if command -v librelane >/dev/null 2>&1; then
    L_VER=$(librelane --version 2>&1 | awk '{print $NF}' || echo "detected")
    log_info "${TOOL_NAME} is already installed (v${L_VER})."
else
    log_info "Installing LibreLane (pin: ${LIBRELANE_PIN}) into venv..."
    run_cmd pip install --upgrade pip
    run_cmd pip install "librelane==${LIBRELANE_PIN}" || run_cmd pip install librelane
fi

# Ensure PDK manager is set up
"${SCRIPT_DIR}/scripts/tools/ciel.sh"

# VERIFY step
log_step "Verifying ${TOOL_NAME}..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME}" "INSTALLED" "dry-run"
    exit 0
fi

if command -v librelane >/dev/null 2>&1; then
    L_VER=$(librelane --version 2>&1 | awk '{print $NF}' || echo "installed")
    log_info "Running official LibreLane smoke test (dockerized)..."
    
    # Check if current shell session can access Docker without sudo
    SMOKE_CMD="librelane --dockerized --smoke-test"
    if ! docker ps >/dev/null 2>&1 && sudo docker ps >/dev/null 2>&1; then
        log_info "Running smoke test with sudo for active session (until re-login)..."
        SMOKE_CMD="sudo ${EDA_VENV}/bin/librelane --dockerized --smoke-test"
    fi

    if ${SMOKE_CMD} 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Verified ${TOOL_NAME} v${L_VER} (smoke test passed)."
        record_summary "${TOOL_NAME}" "PASSED" "v${L_VER} (smoke test passed)"
    else
        log_warn "Smoke test failed or requires docker service startup. Please ensure Docker daemon is active."
        record_summary "${TOOL_NAME}" "FAILED" "v${L_VER} (smoke test failed)"
    fi
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "librelane not in venv PATH"
    exit 1
fi
