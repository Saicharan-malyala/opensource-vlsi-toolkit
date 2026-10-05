#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/gh.sh - Install and Verify GitHub CLI (gh) [OPTIONAL]
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="gh"
log_step "Checking ${TOOL_NAME} (OPTIONAL tool)..."

if command -v gh >/dev/null 2>&1; then
    VER=$(gh --version | head -n1 | awk '{print $3}')
    log_info "${TOOL_NAME} is already installed (v${VER}). Skipping."
    record_summary "${TOOL_NAME} (opt)" "INSTALLED" "v${VER} (already present)"
    exit 0
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install GitHub CLI (gh) official repository keyring and package"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y curl
        run_cmd sudo mkdir -p -m 755 /etc/apt/keyrings
        run_cmd curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        run_cmd sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y gh
        ;;
    dnf)
        request_sudo "Install GitHub CLI (gh) using dnf"
        run_cmd sudo dnf install -y 'dnf-command(config-manager)'
        run_cmd sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        run_cmd sudo dnf install -y gh
        ;;
    pacman)
        request_sudo "Install GitHub CLI (gh) using pacman"
        run_cmd sudo pacman -Sy --noconfirm github-cli
        ;;
    zypper)
        request_sudo "Install GitHub CLI (gh) using zypper"
        run_cmd sudo zypper install -y gh
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "GitHub CLI (gh)"
        record_summary "${TOOL_NAME} (opt)" "SKIPPED" "Unsupported package manager"
        exit 0
        ;;
esac

# VERIFY step
log_step "Verifying ${TOOL_NAME}..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME} (opt)" "INSTALLED" "dry-run"
    exit 0
fi

if command -v gh >/dev/null 2>&1; then
    VER=$(gh --version | head -n1 | awk '{print $3}')
    log_success "Verified ${TOOL_NAME} v${VER}."
    record_summary "${TOOL_NAME} (opt)" "INSTALLED" "v${VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME} (opt)" "FAILED" "Binary not on PATH"
    exit 1
fi
