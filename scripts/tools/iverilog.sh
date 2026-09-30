#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/iverilog.sh - Install and Verify Icarus Verilog
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="iverilog"
log_step "Checking ${TOOL_NAME}..."

if command -v iverilog >/dev/null 2>&1; then
    VER=$(iverilog -V 2>&1 | head -n1 | grep -oE '[0-9]+(\.[0-9]+)+' || echo "detected")
    log_info "${TOOL_NAME} is already installed (v${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install iverilog package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y iverilog
        ;;
    dnf)
        request_sudo "Install iverilog package using dnf"
        run_cmd sudo dnf install -y iverilog
        ;;
    pacman)
        request_sudo "Install iverilog package using pacman"
        run_cmd sudo pacman -Sy --noconfirm iverilog
        ;;
    zypper)
        request_sudo "Install iverilog package using zypper"
        run_cmd sudo zypper install -y iverilog
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Icarus Verilog (iverilog)"
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

if command -v iverilog >/dev/null 2>&1; then
    VER=$(iverilog -V 2>&1 | head -n1 | grep -oE '[0-9]+(\.[0-9]+)+' || echo "unknown")
    # Tiny functional simulation test
    TMP_DIR=$(mktemp -d)
    cat << 'EOF' > "${TMP_DIR}/test.v"
module test;
  initial begin
    $display("IVERILOG_SUCCESS");
    $finish;
  end
endmodule
EOF
    iverilog -o "${TMP_DIR}/test.vvp" "${TMP_DIR}/test.v"
    OUT=$(vvp "${TMP_DIR}/test.vvp")
    rm -rf "${TMP_DIR}"

    if echo "${OUT}" | grep -q "IVERILOG_SUCCESS"; then
        log_success "Verified ${TOOL_NAME} v${VER} (simulation functional test passed)."
        record_summary "${TOOL_NAME}" "INSTALLED" "v${VER}"
    else
        log_error "${TOOL_NAME} functional simulation failed."
        record_summary "${TOOL_NAME}" "FAILED" "Simulation test failed"
        exit 1
    fi
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
