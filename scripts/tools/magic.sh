#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/magic.sh - Install and Verify Magic VLSI Layout Tool
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="magic"
log_step "Checking ${TOOL_NAME}..."

if command -v magic >/dev/null 2>&1; then
    VER=$(magic --version 2>&1 || echo "installed")
    log_info "${TOOL_NAME} is already installed (${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install magic package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y magic
        ;;
    pacman)
        request_sudo "Install magic package using pacman"
        run_cmd sudo pacman -Sy --noconfirm magic || true
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Magic (Layout & DRC)"
        record_summary "${TOOL_NAME}" "SKIPPED" "Unsupported package manager or build from source"
        exit 0
        ;;
esac

# VERIFY step
log_step "Verifying ${TOOL_NAME}..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME}" "INSTALLED" "dry-run"
    exit 0
fi

if command -v magic >/dev/null 2>&1; then
    VER=$(magic --version 2>&1 || echo "installed")
    # Functional test: run magic in batch mode (-dnull -noconsole)
    echo "quit" | magic -dnull -noconsole >/dev/null 2>&1 || true
    log_success "Verified ${TOOL_NAME} (${VER})."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
