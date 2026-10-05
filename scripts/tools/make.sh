#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/make.sh - Install and Verify GNU Make
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="make"
MIN_VERSION="${MAKE_MIN_VERSION:-4.3}"

log_step "Checking ${TOOL_NAME}..."

if command -v make >/dev/null 2>&1; then
    CURRENT_VER=$(make --version | head -n1 | awk '{print $3}' | sed 's/[^0-9.]//g')
    if version_gte "${CURRENT_VER}" "${MIN_VERSION}"; then
        log_info "${TOOL_NAME} is already installed (version ${CURRENT_VER} >= ${MIN_VERSION}). Skipping."
        record_summary "${TOOL_NAME}" "INSTALLED" "v${CURRENT_VER} (already present)"
        exit 0
    fi
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install build-essential and make using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y make build-essential
        ;;
    dnf)
        request_sudo "Install make using dnf"
        run_cmd sudo dnf install -y make
        ;;
    pacman)
        request_sudo "Install make using pacman"
        run_cmd sudo pacman -Sy --noconfirm make
        ;;
    zypper)
        request_sudo "Install make using zypper"
        run_cmd sudo zypper install -y make
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "GNU Make"
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

if command -v make >/dev/null 2>&1; then
    INSTALLED_VER=$(make --version | head -n1 | awk '{print $3}')
    # Functional test: run make -f with a simple target
    echo -e "test_target:\n\t@echo make_ok" | make -f - test_target >/dev/null
    log_success "Verified ${TOOL_NAME} version ${INSTALLED_VER} (functional test passed)."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${INSTALLED_VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
