#!/usr/bin/env bash
# ==============================================================================
# scripts/path_b/install_path_b.sh - Part B Orchestrator (IIC-OSIC-TOOLS All-In-One)
# ==============================================================================
# 1. Checks host prerequisites: git, curl, docker (or podman), gh.
# 2. Clones upstream IIC-OSIC-TOOLS repo without overwriting/vendoring files.
# 3. Checks minimum disk space (20 GB required, ~4 GB download).
# 4. Pulls official container image: hpretl/iic-osic-tools:latest.
# 5. Performs GAP CHECK inside container: command -v <tool>.
# 6. Installs any missing tools on host via scripts/tools/<tool>.sh.
# 7. Outputs summary table explaining container vs host boundaries.
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

CONTAINER_IMAGE="${IIC_OSIC_TOOLS_IMAGE:-hpretl/iic-osic-tools:latest}"
UPSTREAM_REPO="${IIC_OSIC_TOOLS_REPO:-https://github.com/iic-jku/IIC-OSIC-TOOLS.git}"
IIC_TARGET_DIR="${SCRIPT_DIR}/upstream_iic_osic_tools"

for arg in "$@"; do
    case "${arg}" in
        --dry-run) export DRY_RUN=1 ;;
        --yes) export ASSUME_YES=1 ;;
        --help)
            echo "Usage: ./scripts/path_b/install_path_b.sh [--dry-run] [--yes] [--help]"
            exit 0
            ;;
    esac
done

log_step "Starting Part B (IIC-OSIC-TOOLS All-In-One Container Flow)..."

# Step 1: Host Prerequisites
log_info "Step 1/5: Checking host prerequisites (git, docker, optional gh)..."
"${SCRIPT_DIR}/scripts/tools/git.sh"
"${SCRIPT_DIR}/scripts/tools/docker.sh"
"${SCRIPT_DIR}/scripts/tools/gh.sh"

# Step 2: Check Free Disk Space (At least 20 GB recommended)
log_info "Step 2/5: Checking disk space..."
if [[ "${DRY_RUN}" -eq 0 ]]; then
    AVAILABLE_KB=$(df -k . | awk 'NR==2 {print $4}')
    # 20 GB = 20971520 KB
    if [[ "${AVAILABLE_KB}" -lt 20971520 ]]; then
        AVAIL_GB=$((AVAILABLE_KB / 1024 / 1024))
        log_warn "Free disk space is ${AVAIL_GB} GB (< 20 GB recommended by upstream IIC-OSIC-TOOLS)."
        log_warn "The container image is ~4 GB compressed and expands to ~12 GB. PDKs require additional space."
    else
        AVAIL_GB=$((AVAILABLE_KB / 1024 / 1024))
        log_success "Sufficient disk space available: ${AVAIL_GB} GB."
    fi
fi

# Step 3: Clone Upstream IIC-OSIC-TOOLS repo (depth 1)
log_info "Step 3/5: Setting up upstream start scripts..."
if [[ -d "${IIC_TARGET_DIR}/.git" ]]; then
    log_info "Upstream repo already cloned at ${IIC_TARGET_DIR}. Pulling latest..."
    run_cmd git -C "${IIC_TARGET_DIR}" pull --ff-only || true
else
    log_info "Cloning upstream IIC-OSIC-TOOLS start scripts (depth 1)..."
    run_cmd git clone --depth=1 "${UPSTREAM_REPO}" "${IIC_TARGET_DIR}"
fi

# Step 4: Pull Docker Image
log_info "Step 4/5: Pulling container image '${CONTAINER_IMAGE}'..."
log_warn "This download is ~4 GB. Please be patient."
run_cmd docker pull "${CONTAINER_IMAGE}"

# Step 5: Container Gap Check & Host Fallback
log_info "Step 5/5: Running container tool gap check..."
declare -a SCOPE_TOOLS=("yosys" "iverilog" "verilator" "gtkwave" "librelane" "openroad" "magic" "netgen" "klayout" "opensta" "ngspice" "cocotb" "pyuvm" "make")

if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Simulating container gap check."
    for tool in "${SCOPE_TOOLS[@]}"; do
        record_summary "${tool}" "CONTAINER" "Present in ${CONTAINER_IMAGE}"
    done
else
    for tool in "${SCOPE_TOOLS[@]}"; do
        # Translate tool name for CLI check
        CHECK_CMD="${tool}"
        if [[ "${tool}" == "opensta" ]]; then CHECK_CMD="sta"; fi
        if [[ "${tool}" == "cocotb" ]]; then CHECK_CMD="python3 -c 'import cocotb'"; fi
        if [[ "${tool}" == "pyuvm" ]]; then CHECK_CMD="python3 -c 'import pyuvm'"; fi

        # Run check inside container
        if docker run --rm "${CONTAINER_IMAGE}" bash -lc "command -v ${CHECK_CMD} >/dev/null 2>&1 || ${CHECK_CMD} >/dev/null 2>&1" 2>/dev/null; then
            record_summary "${tool}" "CONTAINER" "Pre-installed in image"
        else
            log_warn "Tool '${tool}' was NOT detected inside the container. Installing on host as fallback..."
            if [[ -f "${SCRIPT_DIR}/scripts/tools/${tool}.sh" ]]; then
                "${SCRIPT_DIR}/scripts/tools/${tool}.sh"
            else
                record_summary "${tool}" "SKIPPED" "Not found in container or host script"
            fi
        fi
    done
fi

print_summary_table

log_info "====================================================================="
log_info "IMPORTANT ISOLATION NOTICE:"
log_info "Host tools are NOT visible inside the container, and container tools"
log_info "are NOT visible on the host. Share designs via your design folder:"
log_info "  Default host path:      \$HOME/eda/designs"
log_info "  Mounted inside container: /foss/designs"
log_info ""
log_info "To launch GUI tools via web browser (VNC):"
log_info "  cd upstream_iic_osic_tools && ./start_vnc.sh"
log_info "  Open: http://localhost:80"
log_info "====================================================================="
log_success "Part B setup completed successfully!"
