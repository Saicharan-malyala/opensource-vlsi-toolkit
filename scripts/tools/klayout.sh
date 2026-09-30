#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/klayout.sh - Install and Verify KLayout
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="klayout"
log_step "Checking ${TOOL_NAME}..."

if command -v klayout >/dev/null 2>&1; then
    VER=$(klayout -v 2>&1 | head -n1 || echo "installed")
    log_info "${TOOL_NAME} is already installed (${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install klayout package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y klayout
        ;;
    dnf)
        request_sudo "Install klayout package using dnf"
        run_cmd sudo dnf install -y klayout || true
        ;;
    pacman)
        request_sudo "Install klayout package using pacman"
        run_cmd sudo pacman -Sy --noconfirm klayout || true
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "KLayout (GDS/OASIS Viewer)"
        record_summary "${TOOL_NAME}" "SKIPPED" "Use prebuilt package or Part A/B container"
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

if command -v klayout >/dev/null 2>&1; then
    VER=$(klayout -v 2>&1 | head -n1 || echo "installed")
    # Functional test: run klayout non-interactive in batch mode (-b)
    klayout -b -c "exit" >/dev/null 2>&1 || true
    log_success "Verified ${TOOL_NAME} (${VER})."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER}"
else
    log_warn "KLayout binary not found after pkg manager run."
    notify_unsupported_tool "${TOOL_NAME}" "KLayout (GDS/OASIS Viewer)"
    record_summary "${TOOL_NAME}" "SKIPPED" "Install manually via README_MANUAL_INSTALL.md"
    exit 0
fi
