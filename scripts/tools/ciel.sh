#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/ciel.sh - Install and Verify Ciel PDK Manager (and Sky130 PDK)
# ==============================================================================
# Note: Ciel is the official successor to Volare (FOSSi Foundation).
# It manages pre-built open-source PDKs without manual compiling.
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="ciel"
EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"
CIEL_PIN="${CIEL_VERSION:-3.0.0}"
PDK_FAMILY="${SKY130_PDK_FAMILY:-sky130}"
PDK_ROOT_DIR="${PDK_ROOT:-${HOME}/.ciel}"

log_step "Checking ${TOOL_NAME} PDK manager..."

# Ensure python venv exists
"${SCRIPT_DIR}/scripts/tools/python.sh"
if [[ ! -d "${EDA_VENV}" ]]; then
    run_cmd python3 -m venv "${EDA_VENV}"
fi
# shellcheck disable=SC1091
source "${EDA_VENV}/bin/activate"

if command -v ciel >/dev/null 2>&1; then
    CIEL_CUR=$(ciel --version 2>&1 | awk '{print $NF}' || echo "detected")
    log_info "${TOOL_NAME} is already installed (v${CIEL_CUR})."
else
    log_info "Installing ciel (pin: ${CIEL_PIN}) into venv..."
    run_cmd pip install --upgrade pip
    run_cmd pip install "ciel==${CIEL_PIN}" || run_cmd pip install ciel
fi

# VERIFY step
log_step "Verifying ${TOOL_NAME} and checking ${PDK_FAMILY} PDK status..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME}" "INSTALLED" "dry-run"
    exit 0
fi

if command -v ciel >/dev/null 2>&1; then
    VER=$(ciel --version 2>&1 | awk '{print $NF}' || echo "installed")
    log_success "Verified ${TOOL_NAME} v${VER}."

    # Verify or fetch PDK if not already present
    log_step "Checking local PDK root at ${PDK_ROOT_DIR}..."
    export PDK_ROOT="${PDK_ROOT_DIR}"
    mkdir -p "${PDK_ROOT_DIR}"

    if ciel ls --pdk-family="${PDK_FAMILY}" 2>/dev/null | grep -q "installed"; then
        log_info "${PDK_FAMILY} PDK is already installed in ${PDK_ROOT_DIR}."
    else
        log_info "Enabling default ${PDK_FAMILY} PDK via ciel (this may take a few minutes)..."
        run_cmd ciel enable --pdk-family="${PDK_FAMILY}" || {
            log_warn "ciel enable returned non-zero (network or pre-built asset download issue). You can re-run 'ciel enable --pdk-family=${PDK_FAMILY}' later."
        }
    fi
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER} (PDK: ${PDK_FAMILY})"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "ciel not in venv PATH"
    exit 1
fi
