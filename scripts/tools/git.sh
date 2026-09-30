#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/git.sh - Install and Verify Git
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="git"
MIN_VERSION="${GIT_MIN_VERSION:-2.35.0}"

log_step "Checking ${TOOL_NAME}..."

if command -v git >/dev/null 2>&1; then
    CURRENT_VER=$(git --version | awk '{print $3}' | sed 's/[^0-9.]//g')
    if version_gte "${CURRENT_VER}" "${MIN_VERSION}"; then
        log_info "${TOOL_NAME} is already installed (version ${CURRENT_VER} >= ${MIN_VERSION}). Skipping."
        record_summary "${TOOL_NAME}" "INSTALLED" "v${CURRENT_VER} (already present)"
        exit 0
    else
        log_warn "${TOOL_NAME} version ${CURRENT_VER} is older than recommended ${MIN_VERSION}. Updating..."
    fi
fi

PKG_MGR=$(detect_pkg_mgr)
log_info "Detected package manager: ${PKG_MGR}"

case "${PKG_MGR}" in
    apt)
        request_sudo "Install git package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y git
        ;;
    dnf)
        request_sudo "Install git package using dnf"
        run_cmd sudo dnf install -y git
        ;;
    pacman)
        request_sudo "Install git package using pacman"
        run_cmd sudo pacman -Sy --noconfirm git
        ;;
    zypper)
        request_sudo "Install git package using zypper"
        run_cmd sudo zypper install -y git
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Git"
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

if command -v git >/dev/null 2>&1; then
    INSTALLED_VER=$(git --version | awk '{print $3}')
    # Functional test: init and config check
    TMP_TEST=$(mktemp -d)
    git init -q "${TMP_TEST}"
    rm -rf "${TMP_TEST}"
    log_success "Verified ${TOOL_NAME} version ${INSTALLED_VER} (functional test passed)."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${INSTALLED_VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
