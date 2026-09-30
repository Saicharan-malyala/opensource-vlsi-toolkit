#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/gtkwave.sh - Install and Verify GTKWave
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="gtkwave"
log_step "Checking ${TOOL_NAME}..."

if command -v gtkwave >/dev/null 2>&1; then
    VER=$(gtkwave --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "detected")
    log_info "${TOOL_NAME} is already installed (v${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install gtkwave package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y gtkwave
        ;;
    dnf)
        request_sudo "Install gtkwave package using dnf"
        run_cmd sudo dnf install -y gtkwave
        ;;
    pacman)
        request_sudo "Install gtkwave package using pacman"
        run_cmd sudo pacman -Sy --noconfirm gtkwave
        ;;
    zypper)
        request_sudo "Install gtkwave package using zypper"
        run_cmd sudo zypper install -y gtkwave
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "GTKWave"
        record_summary "${TOOL_NAME}" "SKIPPED" "Unsupported package manager"
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

if command -v gtkwave >/dev/null 2>&1; then
    VER=$(gtkwave --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "installed")
    # Functional test: gtkwave --help
    gtkwave --help >/dev/null 2>&1 || true
    log_success "Verified ${TOOL_NAME} v${VER}."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
