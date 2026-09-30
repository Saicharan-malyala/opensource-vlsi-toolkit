#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/verilator.sh - Install and Verify Verilator
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="verilator"
log_step "Checking ${TOOL_NAME}..."

if command -v verilator >/dev/null 2>&1; then
    VER=$(verilator --version | awk '{print $2}')
    log_info "${TOOL_NAME} is already installed (v${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install verilator package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y verilator
        ;;
    dnf)
        request_sudo "Install verilator package using dnf"
        run_cmd sudo dnf install -y verilator
        ;;
    pacman)
        request_sudo "Install verilator package using pacman"
        run_cmd sudo pacman -Sy --noconfirm verilator
        ;;
    zypper)
        request_sudo "Install verilator package using zypper"
        run_cmd sudo zypper install -y verilator
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Verilator"
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

if command -v verilator >/dev/null 2>&1; then
    VER=$(verilator --version | awk '{print $2}')
    # Functional test: lint a trivial module
    TMP_DIR=$(mktemp -d)
    cat << 'EOF' > "${TMP_DIR}/top.v"
module top(input clk, input rst, output reg [3:0] q);
  always @(posedge clk or posedge rst) begin
    if (rst) q <= 4'b0;
    else q <= q + 1'b1;
  end
endmodule
EOF
    verilator --lint-only -Wall "${TMP_DIR}/top.v"
    rm -rf "${TMP_DIR}"

    log_success "Verified ${TOOL_NAME} v${VER} (lint functional test passed)."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
