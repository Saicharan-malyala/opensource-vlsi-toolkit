#!/usr/bin/env bash
# ==============================================================================
# scripts/optional/github_setup.sh - Optional Git Identity & GitHub CLI Setup
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Configuring Git User Identity & GitHub Authentication..."

# 1. Git user.name and user.email
CURRENT_NAME=$(git config --global user.name || echo "")
CURRENT_EMAIL=$(git config --global user.email || echo "")

if [[ -n "${CURRENT_NAME}" && -n "${CURRENT_EMAIL}" ]]; then
    log_info "Git identity is already set:"
    log_info "  user.name:  ${CURRENT_NAME}"
    log_info "  user.email: ${CURRENT_EMAIL}"
    read -r -p "Do you want to change these settings? [y/N]: " change_id
    if [[ "${change_id}" =~ ^[yY] ]]; then
        read -r -p "Enter new Git Name: " NEW_NAME
        read -r -p "Enter new Git Email: " NEW_EMAIL
        git config --global user.name "${NEW_NAME}"
        git config --global user.email "${NEW_EMAIL}"
        log_success "Updated global git user configuration."
    fi
else
    log_info "Git user identity is not fully configured."
    if [[ "${ASSUME_YES}" -eq 1 ]]; then
        log_warn "Skipping interactive identity entry (--yes passed)."
    else
        read -r -p "Enter your Full Name (for Git commits): " NEW_NAME
        read -r -p "Enter your Email Address: " NEW_EMAIL
        if [[ -n "${NEW_NAME}" && -n "${NEW_EMAIL}" ]]; then
            git config --global user.name "${NEW_NAME}"
            git config --global user.email "${NEW_EMAIL}"
            log_success "Saved global git user configuration."
        fi
    fi
fi

# 2. GitHub CLI Login Check
if command -v gh >/dev/null 2>&1; then
    log_info "Checking GitHub CLI (gh) authentication status..."
    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI is authenticated."
    else
        log_info "GitHub CLI is not currently logged in."
        if [[ "${ASSUME_YES}" -eq 0 && "${DRY_RUN}" -eq 0 ]]; then
            read -r -p "Would you like to log in to GitHub now using 'gh auth login'? [y/N]: " login_gh
            if [[ "${login_gh}" =~ ^[yY] ]]; then
                gh auth login
            fi
        fi
    fi
else
    log_info "GitHub CLI (gh) is not installed on this system. You can install it anytime via:"
    log_info "  ./scripts/tools/gh.sh"
fi

log_success "GitHub & Git identity setup step complete."
