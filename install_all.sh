#!/usr/bin/env bash
# ==============================================================================
# install_all.sh - Root Entry Point for Open-Source EDA Installer
# ==============================================================================
# Usage:
#   ./install_all.sh                 Interactive selection menu
#   ./install_all.sh --path a        Part A: LibreLane (Docker + Ciel + Host tools)
#   ./install_all.sh --path b        Part B: IIC-OSIC-TOOLS (All-In-One Container)
#   ./install_all.sh --path manual   Runs doctor check and points to manual guide
#
# Flags:
#   --dry-run       Print commands without executing
#   --yes           Skip interactive confirmation prompts
#   --help          Show help message
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

SELECTED_PATH=""

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            SELECTED_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --yes)
            ASSUME_YES=1
            shift
            ;;
        --help|-h)
            echo "Open-Source EDA Tools Installer"
            echo ""
            echo "Usage: ./install_all.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --path [a|b|manual]  Select installation path directly:"
            echo "                         a: LibreLane modern flow + host tools"
            echo "                         b: IIC-OSIC-TOOLS all-in-one container"
            echo "                         manual: Standalone manual guide mode"
            echo "  --dry-run            Print commands without executing"
            echo "  --yes                Automatically answer yes to prompts"
            echo "  --help, -h           Display this help screen"
            echo ""
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run ./install_all.sh --help for usage."
            exit 1
            ;;
    esac
done

export DRY_RUN
export ASSUME_YES

log_step "Initializing Open-Source EDA Tools Installer..."
log_info "Logging session to: ${LOG_FILE}"

# If no path specified on CLI, display interactive menu
if [[ -z "${SELECTED_PATH}" ]]; then
    echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
    echo -e "${COLOR_CYAN}${COLOR_BOLD}           WELCOME TO THE OPEN-SOURCE EDA TOOLS INSTALLER            ${COLOR_RESET}"
    echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
    echo "Please choose your preferred installation path:"
    echo ""
    echo "  [1] Part A: LibreLane Flow (Recommended for digital ASIC RTL-to-GDSII)"
    echo "              - Installs LibreLane with Docker execution backend"
    echo "              - Sets up Ciel PDK manager and Sky130 PDK"
    echo "              - Installs host simulation & verification tools (iverilog, verilator, cocotb)"
    echo ""
    echo "  [2] Part B: IIC-OSIC-TOOLS (All-In-One Container from JKU Linz)"
    echo "              - Single ~4 GB container image with 50+ EDA tools pre-installed"
    echo "              - Built-in VNC desktop, X11 forwarding, multi-PDK support"
    echo "              - Automated gap check to install any missing tools on host"
    echo ""
    echo "  [3] Part C: Standalone Manual Guide Mode"
    echo "              - Run diagnostic doctor check and print manual instructions"
    echo ""
    echo "  [4] Exit"
    echo ""

    if [[ "${ASSUME_YES}" -eq 1 ]]; then
        SELECTED_PATH="a"
        log_info "Defaulting to Path A (--yes specified)."
    else
        read -r -p "Enter choice [1-4] (default: 1): " user_choice
        case "${user_choice}" in
            1|"") SELECTED_PATH="a" ;;
            2)    SELECTED_PATH="b" ;;
            3)    SELECTED_PATH="manual" ;;
            4)    log_info "Installation cancelled by user."; exit 0 ;;
            *)    log_error "Invalid selection: ${user_choice}"; exit 1 ;;
        esac
    fi
fi

# Route Execution Based on Choice
case "${SELECTED_PATH,,}" in
    a|1)
        log_step "Executing Part A: LibreLane Flow Installation..."
        "${SCRIPT_DIR}/scripts/path_a/install_path_a.sh"
        ;;
    b|2)
        log_step "Executing Part B: IIC-OSIC-TOOLS Installation..."
        "${SCRIPT_DIR}/scripts/path_b/install_path_b.sh"
        ;;
    manual|c|3)
        log_step "Part C: Manual Guide Mode Selected."
        log_info "Please refer to README_MANUAL_INSTALL.md for step-by-step hand-typed instructions."
        ;;
    *)
        log_error "Unknown path '${SELECTED_PATH}'. Must be 'a', 'b', or 'manual'."
        exit 1
        ;;
esac

# Post-install Health Verification using doctor.sh
echo ""
log_step "Running system health diagnostics (doctor.sh)..."
if "${SCRIPT_DIR}/doctor.sh"; then
    log_success "All systems verified successfully!"
else
    log_warn "Doctor reported warnings or missing components. Check the table above for instructions."
fi

# Optional GitHub user setup prompt
if [[ "${DRY_RUN}" -eq 0 && "${ASSUME_YES}" -eq 0 ]]; then
    read -r -p "Would you like to configure your Git user identity and GitHub CLI now? [y/N]: " setup_gh
    if [[ "${setup_gh}" =~ ^[yY] ]]; then
        "${SCRIPT_DIR}/scripts/optional/github_setup.sh"
    fi
fi

log_success "Installer completed. See ${LOG_FILE} for full installation details."
