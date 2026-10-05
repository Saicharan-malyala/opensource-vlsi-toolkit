#!/usr/bin/env bash
# ==============================================================================
# doctor.sh - Verification and Health Diagnostic Tool
# ==============================================================================
# Rule: NEVER installs anything. Read-only verification.
# Inspects environment, checks tool versions, checks container availability,
# and prints a clear PASS/FAIL diagnostic summary table.
# Exits with 0 if all core tools pass, non-zero if any required tool fails.
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}             EDA ENVIRONMENT DOCTOR & SYSTEM DIAGNOSTIC              ${COLOR_RESET}"
echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
echo -e "Hostname:         $(hostname)"
echo -e "Kernel / OS:      $(uname -sr)"
echo -e "User:             $(whoami) (UID: $(id -u))"
echo -e "Date / Timestamp: $(date)"
echo -e "Package Manager:  $(detect_pkg_mgr)"
echo ""

FAIL_COUNT=0
WARN_COUNT=0

declare -a DOC_NAMES=()
declare -a DOC_RESULTS=()
declare -a DOC_DETAILS=()

check_item() {
    local name="$1"
    local is_required="$2" # 1 = required, 0 = optional
    local check_type="$3"  # "cmd" | "python" | "docker" | "pdk"
    local check_target="$4"

    local status="FAIL"
    local detail="Not found"

    case "${check_type}" in
        cmd)
            if command -v "${check_target}" >/dev/null 2>&1; then
                local ver
                ver=$("${check_target}" --version 2>&1 | head -n1 || echo "present")
                status="PASS"
                detail="${ver:0:30}"
            fi
            ;;
        python)
            EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"
            if [[ -f "${EDA_VENV}/bin/python3" ]]; then
                if "${EDA_VENV}/bin/python3" -c "import ${check_target}" >/dev/null 2>&1; then
                    local ver
                    ver=$("${EDA_VENV}/bin/python3" -c "import ${check_target}; print(getattr(${check_target}, '__version__', 'ok'))" 2>/dev/null || echo "ok")
                    status="PASS"
                    detail="v${ver} (venv)"
                fi
            elif command -v python3 >/dev/null 2>&1; then
                if python3 -c "import ${check_target}" >/dev/null 2>&1; then
                    local ver
                    ver=$(python3 -c "import ${check_target}; print(getattr(${check_target}, '__version__', 'ok'))" 2>/dev/null || echo "ok")
                    status="PASS"
                    detail="v${ver} (system)"
                fi
            fi
            ;;
        docker)
            if command -v docker >/dev/null 2>&1; then
                if docker info >/dev/null 2>&1; then
                    status="PASS"
                    detail="Daemon responding"
                else
                    status="WARN"
                    detail="Docker installed, daemon not running or need group"
                fi
            fi
            ;;
        pdk)
            EDA_VENV="${EDA_VENV:-${HOME}/.eda_venv}"
            PDK_DIR="${PDK_ROOT:-${HOME}/.ciel}"
            if [[ -d "${PDK_DIR}/sky130A" ]] || [[ -d "${PDK_DIR}/sky130B" ]]; then
                status="PASS"
                detail="PDK present in ${PDK_DIR}"
            elif [[ -f "${EDA_VENV}/bin/ciel" ]]; then
                status="WARN"
                detail="ciel installed, PDK download needed"
            fi
            ;;
    esac

    if [[ "${status}" == "FAIL" ]]; then
        if [[ "${is_required}" -eq 1 ]]; then
            FAIL_COUNT=$((FAIL_COUNT + 1))
        else
            status="WARN"
            WARN_COUNT=$((WARN_COUNT + 1))
        fi
    elif [[ "${status}" == "WARN" ]]; then
        WARN_COUNT=$((WARN_COUNT + 1))
    fi

    DOC_NAMES+=("${name}")
    DOC_RESULTS+=("${status}")
    DOC_DETAILS+=("${detail}")
}

# Run diagnostics across all tools in scope
log_step "Probing installed tools and runtime environments..."

check_item "Git" 1 "cmd" "git"
check_item "GNU Make" 1 "cmd" "make"
check_item "Python 3" 1 "cmd" "python3"
check_item "Docker Engine" 1 "docker" "docker"
check_item "Icarus Verilog" 1 "cmd" "iverilog"
check_item "Verilator" 1 "cmd" "verilator"
check_item "GTKWave" 1 "cmd" "gtkwave"
check_item "ngspice" 1 "cmd" "ngspice"
check_item "cocotb" 1 "python" "cocotb"
check_item "pyuvm" 1 "python" "pyuvm"
check_item "LibreLane" 0 "python" "librelane"
check_item "Ciel PDK Manager" 0 "python" "ciel"
check_item "Sky130 PDK" 0 "pdk" "sky130"
check_item "Yosys (Host)" 0 "cmd" "yosys"
check_item "OpenROAD (Host)" 0 "cmd" "openroad"
check_item "OpenSTA (Host)" 0 "cmd" "sta"
check_item "Magic (Host)" 0 "cmd" "magic"
check_item "Netgen (Host)" 0 "cmd" "netgen"
check_item "KLayout (Host)" 0 "cmd" "klayout"
check_item "GitHub CLI (gh)" 0 "cmd" "gh"
check_item "Xschem (Host)" 0 "cmd" "xschem"

echo ""
echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}                      DOCTOR DIAGNOSTIC RESULTS                      ${COLOR_RESET}"
echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
printf "%-22s | %-8s | %-32s\n" "Diagnostic Target" "Status" "Version / Notes"
echo "-----------------------+----------+----------------------------------"

total=${#DOC_NAMES[@]}
for ((idx=0; idx<total; idx++)); do
    name="${DOC_NAMES[$idx]}"
    res="${DOC_RESULTS[$idx]}"
    det="${DOC_DETAILS[$idx]}"
    color="${COLOR_GREEN}"
    if [[ "${res}" == "FAIL" ]]; then
        color="${COLOR_RED}"
    elif [[ "${res}" == "WARN" ]]; then
        color="${COLOR_YELLOW}"
    fi
    printf "%-22s | ${color}%-8s${COLOR_RESET} | %-32s\n" "${name}" "${res}" "${det}"
done
echo -e "${COLOR_BOLD}=====================================================================${COLOR_RESET}"
echo ""

if [[ ${FAIL_COUNT} -eq 0 ]]; then
    if [[ ${WARN_COUNT} -eq 0 ]]; then
        log_success "DOCTOR PASSED: All monitored tools and environments are healthy!"
    else
        log_warn "DOCTOR PASSED with warnings (${WARN_COUNT} optional or container-backed tools not detected on host)."
        log_info "Note: In Part A and Part B, ASIC flow tools (Yosys, OpenROAD, Magic, etc.) run inside containers."
    fi
    exit 0
else
    log_error "DOCTOR FAILED: ${FAIL_COUNT} required component(s) failed validation."
    log_info "To resolve, run: ./install_all.sh --path [a|b|manual]"
    exit 1
fi
