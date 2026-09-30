#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/openroad.sh - Install and Verify OpenROAD
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="openroad"
log_step "Checking ${TOOL_NAME}..."

if command -v openroad >/dev/null 2>&1; then
    VER=$(openroad -version 2>&1 | head -n1 || echo "installed")
    log_info "${TOOL_NAME} is already installed (${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        log_info "Checking for Precision Innovations / OpenROAD pre-built deb packages..."
        # If running on Ubuntu 22.04 / 24.04, attempt official deb release
        UBUNTU_VER=$(grep VERSION_ID /etc/os-release 2>/dev/null | tr -d '"' | cut -d= -f2 || echo "22.04")
        PREBUILT_URL="https://github.com/The-OpenROAD-Project/OpenROAD/releases/download/${OPENROAD_VERSION}/openroad_${OPENROAD_VERSION#v}_amd64-ubuntu-${UBUNTU_VER}.deb"
        
        request_sudo "Install OpenROAD dependencies and prebuilt debian package"
        run_cmd sudo apt-get update -y
        # Try downloading prebuilt package if curl succeeds
        TMP_DEB=$(mktemp --suffix=.deb)
        if curl -fsSL -o "${TMP_DEB}" "${PREBUILT_URL}" 2>/dev/null; then
            log_info "Downloaded official OpenROAD prebuilt package."
            run_cmd sudo apt-get install -y "${TMP_DEB}" || sudo apt-get install -f -y
            rm -f "${TMP_DEB}"
        else
            rm -f "${TMP_DEB}"
            log_warn "Prebuilt package not available directly for this architecture/version via direct link."
            notify_unsupported_tool "${TOOL_NAME}" "OpenROAD (Place & Route)"
            record_summary "${TOOL_NAME}" "SKIPPED" "Use prebuilt or Part A container"
            exit 0
        fi
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "OpenROAD (Place & Route)"
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

if command -v openroad >/dev/null 2>&1; then
    VER=$(openroad -version 2>&1 | head -n1 || echo "installed")
    # Functional test: run openroad -exit
    echo "exit" | openroad >/dev/null 2>&1
    log_success "Verified ${TOOL_NAME} (${VER})."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
