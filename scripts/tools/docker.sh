#!/usr/bin/env bash
# ==============================================================================
# scripts/tools/docker.sh - Install and Verify Docker Engine (and optional Podman)
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

TOOL_NAME="docker"
MIN_VERSION="${DOCKER_MIN_VERSION:-25.0.5}"
USE_PODMAN="${USE_PODMAN:-0}"

# Handle --podman flag if passed as argument
for arg in "$@"; do
    if [[ "${arg}" == "--podman" ]]; then
        USE_PODMAN=1
    fi
done

if [[ "${USE_PODMAN}" -eq 1 ]]; then
    TOOL_NAME="podman"
    log_step "Checking Podman..."
    if command -v podman >/dev/null 2>&1; then
        P_VER=$(podman --version | awk '{print $3}')
        log_info "Podman is already installed (v${P_VER}). Skipping."
        record_summary "${TOOL_NAME}" "INSTALLED" "v${P_VER} (already present)"
        exit 0
    fi
    PKG_MGR=$(detect_pkg_mgr)
    case "${PKG_MGR}" in
        apt)
            request_sudo "Install podman via apt"
            run_cmd sudo apt-get update -y
            run_cmd sudo apt-get install -y podman
            ;;
        dnf)
            request_sudo "Install podman via dnf"
            run_cmd sudo dnf install -y podman
            ;;
        pacman)
            request_sudo "Install podman via pacman"
            run_cmd sudo pacman -Sy --noconfirm podman
            ;;
        zypper)
            request_sudo "Install podman via zypper"
            run_cmd sudo zypper install -y podman
            ;;
        *)
            notify_unsupported_tool "podman" "Podman"
            record_summary "podman" "SKIPPED" "Unsupported package manager"
            exit 0
            ;;
    esac
    record_summary "podman" "INSTALLED" "v$(podman --version | awk '{print $3}')"
    exit 0
fi

log_step "Checking Docker Engine..."

if command -v docker >/dev/null 2>&1; then
    D_VER=$(docker --version | awk '{print $3}' | tr -d ',')
    if version_gte "${D_VER}" "${MIN_VERSION}"; then
        log_info "Docker is already installed (v${D_VER} >= ${MIN_VERSION})."
        # Check docker group membership
        if groups | grep -q "\bdocker\b"; then
            log_info "User '$(whoami)' is already in the 'docker' group."
        else
            log_warn "User '$(whoami)' is NOT in the 'docker' group. Sudo-less docker may fail."
            request_sudo "Add $(whoami) to docker group to allow running without sudo"
            run_cmd sudo usermod -aG docker "$(whoami)"
            log_warn "Added to group. You MUST run 'newgrp docker' or re-login for group changes to take effect."
        fi
        record_summary "${TOOL_NAME}" "INSTALLED" "v${D_VER}"
        exit 0
    fi
fi

PKG_MGR=$(detect_pkg_mgr)
case "${PKG_MGR}" in
    apt)
        request_sudo "Install official Docker CE engine packages via apt"
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y ca-certificates curl gnupg
        run_cmd sudo install -m 0755 -d /etc/apt/keyrings
        if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
            run_cmd curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            run_cmd sudo chmod a+r /etc/apt/keyrings/docker.gpg
        fi
        UBUNTU_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 || echo "jammy")
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        run_cmd sudo apt-get update -y
        run_cmd sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    dnf)
        request_sudo "Install docker-ce via dnf"
        run_cmd sudo dnf -y install dnf-plugins-core
        run_cmd sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        run_cmd sudo dnf install -y docker-ce docker-ce-cli containerd.io
        run_cmd sudo systemctl start docker || true
        ;;
    pacman)
        request_sudo "Install docker via pacman"
        run_cmd sudo pacman -Sy --noconfirm docker
        run_cmd sudo systemctl start docker || true
        ;;
    zypper)
        request_sudo "Install docker via zypper"
        run_cmd sudo zypper install -y docker
        run_cmd sudo systemctl start docker || true
        ;;
    *)
        notify_unsupported_tool "${TOOL_NAME}" "Docker"
        record_summary "${TOOL_NAME}" "SKIPPED" "Unsupported package manager"
        exit 0
        ;;
esac

# Post-install: add user to docker group
request_sudo "Add $(whoami) to the docker group so you can run docker without root"
run_cmd sudo groupadd -f docker
run_cmd sudo usermod -aG docker "$(whoami)"
log_warn "Added user '$(whoami)' to 'docker' group. Remember to run 'newgrp docker' or re-login."

# VERIFY step
log_step "Verifying ${TOOL_NAME}..."
if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "[DRY-RUN] Verification simulated."
    record_summary "${TOOL_NAME}" "INSTALLED" "dry-run"
    exit 0
fi

if command -v docker >/dev/null 2>&1; then
    D_VER=$(docker --version | awk '{print $3}' | tr -d ',')
    log_success "Verified ${TOOL_NAME} version ${D_VER}."
    record_summary "${TOOL_NAME}" "INSTALLED" "v${D_VER}"
else
    log_error "Failed to verify ${TOOL_NAME}."
    record_summary "${TOOL_NAME}" "FAILED" "Binary not on PATH"
    exit 1
fi
