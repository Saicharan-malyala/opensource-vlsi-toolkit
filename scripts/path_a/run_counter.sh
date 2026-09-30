#!/usr/bin/env bash
# ==============================================================================
# scripts/path_a/run_counter.sh - Run Example Counter Design Through LibreLane
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"
if [[ -f "${EDA_VENV}/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "${EDA_VENV}/bin/activate"
fi

if ! command -v librelane >/dev/null 2>&1; then
    log_error "LibreLane is not installed in PATH or ${EDA_VENV}. Please run install_all.sh --path a first."
    exit 1
fi

DESIGN_DIR="${SCRIPT_DIR}/examples/counter"
log_step "Executing LibreLane flow for 4-bit counter design..."
log_info "Design directory: ${DESIGN_DIR}"

run_cmd librelane --dockerized "${DESIGN_DIR}"

log_success "Counter design successfully processed through LibreLane!"
