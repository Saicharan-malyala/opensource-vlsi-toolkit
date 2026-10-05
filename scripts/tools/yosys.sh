#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/yosys.sh - Install and Verify Yosys
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="yosys"
log_step "Checking ${TOOL_NAME}..."

if command -v yosys >/dev/null 2>&1; then
    VER=$(yosys -V 2>&1 | awk '{print $2}' || echo "installed")
    log_info "${TOOL_NAME} is already installed (v${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install yosys package using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y yosys
        ;;
    dnf)
        request_sudo "Install yosys package using dnf"
        run_cmd sudo dnf install -y yosys
        ;;
    pacman)
        request_sudo "Install yosys package using pacman"
        run_cmd sudo pacman -Sy --noconfirm yosys
        ;;
    zypper)
        request_sudo "Install yosys package using zypper"
        run_cmd sudo zypper install -y yosys
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Yosys (Synthesis)"
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

if command -v yosys >/dev/null 2>&1; then
    VER=$(yosys -V 2>&1 | awk '{print $2}' || echo "installed")
    # Tiny functional synthesis test
    TMP_DIR=$(mktemp -d)
    cat << 'EOF' > "${TMP_DIR}/test.v"
module inv(input a, output y);
  assign y = ~a;
endmodule
EOF
    yosys -p "read_verilog ${TMP_DIR}/test.v; synth; stat" > "${TMP_DIR}/yosys.log" 2>&1
    rm -rf "${TMP_DIR}"

    log_success "Verified ${TOOL_NAME} v${VER} (synthesis functional test passed)."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
