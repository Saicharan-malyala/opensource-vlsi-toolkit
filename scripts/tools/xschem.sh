#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/xschem.sh - Install and Verify Xschem (Schematic Capture) [OPTIONAL]
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="xschem"
log_step "Checking ${TOOL_NAME} (OPTIONAL)..."

if command -v xschem >/dev/null 2>&1; then
    VER=$(xschem --version 2>&1 | head -n1 || echo "installed")
    log_info "${TOOL_NAME} is already installed (${VER}). Skipping."
    record_summary "${TOOL_NAME} (opt)" "INSTALLED" "${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install xschem package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y xschem || true
        ;;
    pacman)
        request_sudo "Install xschem package using pacman"
        run_cmd sudo pacman -Sy --noconfirm xschem || true
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Xschem (Schematic Capture)"
        record_summary "${TOOL_NAME} (opt)" "SKIPPED" "Use Part B container or build from source"
        exit 0
        ;;
esac

# VERIFY step
log_step "Verifying ${TOOL_NAME}..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME} (opt)" "INSTALLED" "dry-run"
    exit 0
fi

if command -v xschem >/dev/null 2>&1; then
    VER=$(xschem --version 2>&1 | head -n1 || echo "installed")
    log_success "Verified ${TOOL_NAME} (${VER})."
    record_summary "${TOOL_NAME} (opt)" "INSTALLED" "${VER}"
else
    log_warn "Xschem binary not found."
    notify_unsupported_tool "${TOOL_NAME}" "Xschem (Schematic Capture)"
    record_summary "${TOOL_NAME} (opt)" "SKIPPED" "Install manually via README_MANUAL_INSTALL.md"
    exit 0
fi
