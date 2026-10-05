#!/usr/bin/env bash
# ==============================================================================
# lib/common.sh - Shared Helper Library for Open-Source EDA Installer
# ==============================================================================
# Provides:
# - Bash sanity options (set -euo pipefail)
# - Standardized ANSI color output and logging
# - Dry-run wrapper (run_cmd)
# - Interactive sudo prompts with [y/N] safety
# - Linux package manager detection (apt, dnf, pacman, zypper)
# - Semantic version comparison utility
# - Markdown-style tabular summary renderer
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    COLOR_RESET="\033[0m"
    COLOR_RED="\033[0;31m"
    COLOR_GREEN="\033[0;32m"
    COLOR_YELLOW="\033[0;33m"
    COLOR_BLUE="\033[0;34m"
    COLOR_CYAN="\033[0;36m"
    COLOR_BOLD="\033[1m"
else
    COLOR_RESET=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_CYAN=""
    COLOR_BOLD=""
fi

# Global Option Defaults
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${LOG_DIR}"

if [[ -z "${LOG_FILE:-}" ]]; then
    LOG_FILE="${LOG_DIR}/install_$(date +'%Y%m%d_%H%M%S').log"
fi

# Load versions.env if available
if [[ -f "${SCRIPT_DIR}/versions.env" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/versions.env"
fi

# Logging Functions
log_info() {
    local msg="[INFO] $*"
    echo -e "${COLOR_BLUE}${msg}${COLOR_RESET}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}"
}

log_success() {
    local msg="[SUCCESS] $*"
    echo -e "${COLOR_GREEN}${COLOR_BOLD}${msg}${COLOR_RESET}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}"
}

log_warn() {
    local msg="[WARN] $*"
    echo -e "${COLOR_YELLOW}${msg}${COLOR_RESET}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}"
}

log_error() {
    local msg="[ERROR] $*"
    echo -e "${COLOR_RED}${COLOR_BOLD}${msg}${COLOR_RESET}" >&2
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}"
}

log_step() {
    local msg="==> $*"
    echo -e "${COLOR_CYAN}${COLOR_BOLD}${msg}${COLOR_RESET}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}"
}

# Dry Run Command Wrapper
# In dry-run mode, prints command. Otherwise executes command and appends output to LOG_FILE.
run_cmd() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        echo -e "${COLOR_YELLOW}[DRY-RUN] Would run:${COLOR_RESET} $*"
        echo "$(date +'%Y-%m-%d %H:%M:%S') [DRY-RUN] $*" >> "${LOG_FILE}"
        return 0
    fi

    echo "$(date +'%Y-%m-%d %H:%M:%S') [EXEC] $*" >> "${LOG_FILE}"
    "$@" 2>&1 | tee -a "${LOG_FILE}"
}

# Sudo Prompt Helper
# Explains why sudo is needed, prompts user if not already root or -y
request_sudo() {
    local reason="$1"

    if [[ "$(id -u)" -eq 0 ]]; then
        return 0
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        echo -e "${COLOR_YELLOW}[DRY-RUN] Sudo requested: ${reason}${COLOR_RESET}"
        return 0
    fi

    echo -e "${COLOR_YELLOW}${COLOR_BOLD}[SUDO REQUIRED]${COLOR_RESET} ${reason}"
    if [[ "${ASSUME_YES}" -eq 1 ]]; then
        log_info "Proceeding with sudo (--yes passed)..."
    else
        read -r -p "Allow sudo privilege escalation? [y/N]: " choice
        case "${choice}" in
            [yY][eE][sS]|[yY])
                ;;
            *)
                log_error "Operation cancelled by user (sudo declined)."
                return 1
                ;;
        esac
    fi

    sudo -v || {
        log_error "Failed to acquire sudo credentials."
        return 1
    }
}

# Package Manager Detection
# Detects apt, dnf, pacman, zypper
# Returns: apt | dnf | pacman | zypper | unsupported
detect_pkg_mgr() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unsupported"
    fi
}

# Print standardized unsupported message and reference to Part C manual guide
notify_unsupported_tool() {
    local tool="$1"
    local manual_section="${2:-$1}"
    log_warn "====================================================================="
    log_warn "UNSUPPORTED on this system: ${tool}."
    log_warn "Your package manager or distribution cannot automatically install this."
    log_warn "Install it manually with the exact commands from:"
    log_warn "  README_MANUAL_INSTALL.md -> Section: ${manual_section}"
    log_warn "====================================================================="
}

# Semantic Version Comparison
# Returns 0 if $1 >= $2, 1 if $1 < $2
version_gte() {
    local ver1="$1"
    local ver2="$2"
    # Remove leading 'v' if present
    ver1="${ver1#v}"
    ver2="${ver2#v}"

    # Use sort -V
    if [[ "$(printf '%s\n%s' "${ver2}" "${ver1}" | sort -V | head -n1)" == "${ver2}" ]]; then
        return 0
    else
        return 1
    fi
}

# Summary Table Tracker
declare -a SUMMARY_TOOLS=()
declare -a SUMMARY_STATUSES=()
declare -a SUMMARY_DETAILS=()

record_summary() {
    local tool="$1"
    local status="$2"
    local detail="$3"
    SUMMARY_TOOLS+=("${tool}")
    SUMMARY_STATUSES+=("${status}")
    SUMMARY_DETAILS+=("${detail}")
}

print_summary_table() {
    echo ""
    echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}                       INSTALLATION SUMMARY                          ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
    printf "%-18s | %-12s | %-32s\n" "Tool / Component" "Status" "Details / Version"
    echo "-------------------+--------------+----------------------------------"
    local total=${#SUMMARY_TOOLS[@]}
    for ((i=0; i<total; i++)); do
        local t="${SUMMARY_TOOLS[$i]}"
        local s="${SUMMARY_STATUSES[$i]}"
        local d="${SUMMARY_DETAILS[$i]}"
        local color="${COLOR_RESET}"
        if [[ "${s}" == "INSTALLED" || "${s}" == "PASSED" || "${s}" == "CONTAINER" ]]; then
            color="${COLOR_GREEN}"
        elif [[ "${s}" == "SKIPPED" ]]; then
            color="${COLOR_YELLOW}"
        else
            color="${COLOR_RED}"
        fi
        printf "%-18s | ${color}%-12s${COLOR_RESET} | %-32s\n" "${t}" "${s}" "${d}"
    done
    echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
    echo -e "Full detailed logs available at: ${LOG_FILE}"
    echo ""
}
