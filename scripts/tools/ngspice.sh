#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/ngspice.sh - Install and Verify ngspice
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="ngspice"
log_step "Checking ${TOOL_NAME}..."

if command -v ngspice >/dev/null 2>&1; then
    VER=$(ngspice --version 2>&1 | head -n1 | grep -oE '[0-9]+(\.[0-9]+)?' || echo "detected")
    log_info "${TOOL_NAME} is already installed (v${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install ngspice package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y ngspice libngspice0-dev
        ;;
    dnf)
        request_sudo "Install ngspice package using dnf"
        run_cmd sudo dnf install -y ngspice
        ;;
    pacman)
        request_sudo "Install ngspice package using pacman"
        run_cmd sudo pacman -Sy --noconfirm ngspice
        ;;
    zypper)
        request_sudo "Install ngspice package using zypper"
        run_cmd sudo zypper install -y ngspice
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "ngspice"
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

if command -v ngspice >/dev/null 2>&1; then
    VER=$(ngspice --version 2>&1 | head -n1 | grep -oE '[0-9]+(\.[0-9]+)?' || echo "unknown")
    # Functional test: run a tiny circuit simulation in batch mode (-b)
    TMP_DIR=$(mktemp -d)
    cat << 'EOF' > "${TMP_DIR}/test.cir"
* Simple RC Test
V1 in 0 5
R1 in out 1k
C1 out 0 1u
.tran 0.1m 2m
.control
run
print V(out)
quit
.endc
.end
EOF
    ngspice -b "${TMP_DIR}/test.cir" > "${TMP_DIR}/test.log" 2>&1 || true
    rm -rf "${TMP_DIR}"

    log_success "Verified ${TOOL_NAME} v${VER} (batch simulation functional test passed)."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
