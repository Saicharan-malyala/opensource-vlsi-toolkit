#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/netgen.sh - Install and Verify Netgen (LVS)
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="netgen"
log_step "Checking ${TOOL_NAME}..."

if command -v netgen >/dev/null 2>&1; then
    VER=$(netgen -batch eval "puts \$Netgen::version; exit" 2>&1 | tail -n1 || echo "installed")
    log_info "${TOOL_NAME} is already installed (${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install netgen package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y netgen-lvs || run_cmd sudo apt-get install -y netgen || true
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Netgen (LVS)"
        record_summary "${TOOL_NAME}" "SKIPPED" "Use container or build from source"
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

if command -v netgen >/dev/null 2>&1; then
    VER=$(netgen -batch eval "exit" 2>&1 || echo "installed")
    log_success "Verified ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "INSTALLED" "verified"
else
    log_warn "Netgen binary not found after pkg manager run."
    notify_unsupported_tool "${TOOL_NAME}" "Netgen (LVS)"
    record_summary "${TOOL_NAME}" "SKIPPED" "Install manually via README_MANUAL_INSTALL.md"
    exit 0
fi
