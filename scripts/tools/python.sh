#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/python.sh - Install and Verify Python 3, Pip, Venv, and Tkinter
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="python3"
MIN_VERSION="${PYTHON_MIN_VERSION:-3.10.0}"

log_step "Checking ${TOOL_NAME}, pip, venv, and tkinter..."

check_python_ready() {
    if command -v python3 >/dev/null 2>&1; then
        local ver
        ver=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')
        if version_gte "${ver}" "${MIN_VERSION}"; then
            # Verify tkinter and venv are present
            if python3 -c 'import venv, tkinter; print("ok")' >/dev/null 2>&1; then
                return 0
            fi
        fi
    fi
    return 1
}

if check_python_ready; then
    PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')
    log_info "${TOOL_NAME} (v${PY_VER}) with venv and tkinter is already installed and verified. Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${PY_VER} (venv+tkinter present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install python3, python3-pip, python3-venv, and python3-tk using apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y python3 python3-pip python3-venv python3-tk
        ;;
    dnf)
        request_sudo "Install python3, python3-pip, and python3-tkinter using dnf"
        run_cmd sudo dnf install -y python3 python3-pip python3-tkinter
        ;;
    pacman)
        request_sudo "Install python, python-pip, and tk using pacman"
        run_cmd sudo pacman -Sy --noconfirm python python-pip tk
        ;;
    zypper)
        request_sudo "Install python3, python3-pip, and python3-tk using zypper"
        run_cmd sudo zypper install -y python3 python3-pip python3-tk
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Python 3, Venv, and Tkinter"
        record_summary "${TOOL_NAME}" "SKIPPED" "Unsupported package manager"
        exit 0
        ;;
esac

# VERIFY step
log_step "Verifying ${TOOL_NAME} and required modules..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME}" "INSTALLED" "dry-run"
    exit 0
fi

if command -v python3 >/dev/null 2>&1; then
    PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')
    # Functional test: create temporary venv, import tkinter
    TMP_VENV=$(mktemp -d)
    python3 -m venv "${TMP_VENV}/test_venv"
    # shellcheck disable=SC1091
    source "${TMP_VENV}/test_venv/bin/activate"
    python -c 'import tkinter; assert tkinter.TkVersion is not None'
    deactivate
    rm -rf "${TMP_VENV}"

    log_success "Verified ${TOOL_NAME} version ${PY_VER} (venv and tkinter functional test passed)."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${PY_VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary or modules missing"
    exit 1
fi
