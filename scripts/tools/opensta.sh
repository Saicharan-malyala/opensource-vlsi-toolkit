#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/opensta.sh - Install and Verify OpenSTA
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="opensta"
log_step "Checking ${TOOL_NAME}..."

# OpenSTA binary is 'sta'
if command -v sta >/dev/null 2>&1; then
    VER=$(sta -version 2>&1 | head -n1 || echo "installed")
    log_info "${TOOL_NAME} is already installed (${VER}). Skipping."
    record_summary "${TOOL_NAME}" "INSTALLED" "${VER} (already present)"
    exit 0
fi

# Note: In Part A and Part B, OpenSTA is provided inside the LibreLane / IIC-OSIC-TOOLS container environment.
notify_unsupported_tool "${TOOL_NAME}" "OpenSTA (Static Timing Analysis)"
record_summary "${TOOL_NAME}" "SKIPPED" "Provided via LibreLane/IIC container or compile from source"
exit 0
