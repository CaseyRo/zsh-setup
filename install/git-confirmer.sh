#!/bin/bash
# ============================================================================
# ZSH-Manager: git_confirmer (optional)
# ============================================================================
# Installs and updates git_confirmer from the GitHub repo.
# ============================================================================

GIT_CONFIRMER_REPO_URL="https://github.com/CaseyRo/git_confirmer.git"
GIT_CONFIRMER_MANAGER_ROOT="${ZSH_MANAGER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
GIT_CONFIRMER_PROMPT_FILE="$GIT_CONFIRMER_MANAGER_ROOT/.git-confirmer-prompted"
GIT_CONFIRMER_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/git_confirmer"

git_confirmer_repo_exists() {
    [[ -d "$GIT_CONFIRMER_INSTALL_DIR/.git" ]]
}

git_confirmer_command_installed() {
    command_exists git_confirmer
}

git_confirmer_prompt_state() {
    if [[ -f "$GIT_CONFIRMER_PROMPT_FILE" ]]; then
        cat "$GIT_CONFIRMER_PROMPT_FILE" 2>/dev/null
    fi
}

git_confirmer_update_if_needed() {
    if ! git_confirmer_repo_exists; then
        return 1
    fi

    if ! git -C "$GIT_CONFIRMER_INSTALL_DIR" fetch --quiet; then
        return 1
    fi

    local behind=0
    if git -C "$GIT_CONFIRMER_INSTALL_DIR" rev-parse --abbrev-ref --symbolic-full-name @{upstream} &>/dev/null; then
        behind=$(git -C "$GIT_CONFIRMER_INSTALL_DIR" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    else
        behind=1
    fi

    if [[ "$behind" -gt 0 ]]; then
        if ! run_with_spinner "Updating git_confirmer repo" git -C "$GIT_CONFIRMER_INSTALL_DIR" pull --ff-only; then
            return 1
        fi
        return 0
    fi

    return 2
}

git_confirmer_clone_or_update() {
    mkdir -p "$(dirname "$GIT_CONFIRMER_INSTALL_DIR")"

    if git_confirmer_repo_exists; then
        run_with_spinner "Updating git_confirmer repo" git -C "$GIT_CONFIRMER_INSTALL_DIR" pull --ff-only
        return $?
    fi

    run_with_spinner "Cloning git_confirmer repo" git clone "$GIT_CONFIRMER_REPO_URL" "$GIT_CONFIRMER_INSTALL_DIR"
}

git_confirmer_run_install() {
    if [[ ! -f "$GIT_CONFIRMER_INSTALL_DIR/install.sh" ]]; then
        print_error "git_confirmer install.sh not found"
        return 1
    fi

    run_with_spinner "Installing git_confirmer" bash "$GIT_CONFIRMER_INSTALL_DIR/install.sh"
}

install_git_confirmer() {
    if ! command_exists git; then
        print_error "git is required to install git_confirmer"
        track_failed "git_confirmer"
        return 1
    fi

    local needs_clone=true
    if git_confirmer_repo_exists; then
        local update_status=0
        if git_confirmer_update_if_needed; then
            update_status=0
        else
            update_status=$?
        fi

        if [[ "$update_status" -eq 2 ]] && git_confirmer_command_installed; then
            print_skip "git_confirmer"
            track_skipped "git_confirmer"
            return 0
        fi
        needs_clone=false
        if [[ "$update_status" -eq 1 ]]; then
            print_error "Failed to update git_confirmer"
            track_failed "git_confirmer"
            return 1
        fi
    fi

    print_package "git_confirmer"
    if [[ "$needs_clone" == true ]]; then
        if ! git_confirmer_clone_or_update; then
            print_error "Failed to download git_confirmer"
            track_failed "git_confirmer"
            return 1
        fi
    fi

    if git_confirmer_run_install; then
        print_success "git_confirmer installed"
        track_installed "git_confirmer"
        return 0
    fi

    print_error "Failed to install git_confirmer"
    track_failed "git_confirmer"
    return 1
}

install_git_confirmer_optional() {
    local state
    state=$(git_confirmer_prompt_state)
    if [[ "$state" == "yes" ]]; then
        install_git_confirmer
        return 0
    elif [[ "$state" == "no" ]]; then
        return 0
    fi

    if git_confirmer_command_installed; then
        echo "yes" > "$GIT_CONFIRMER_PROMPT_FILE" 2>/dev/null || true
        return 0
    fi

    if ! ui_confirm "Install git_confirmer from GitHub?"; then
        print_info "Skipping git_confirmer (you can install later via $GIT_CONFIRMER_MANAGER_ROOT/install.sh)."
        echo "no" > "$GIT_CONFIRMER_PROMPT_FILE" 2>/dev/null || true
        return 0
    fi

    echo "yes" > "$GIT_CONFIRMER_PROMPT_FILE" 2>/dev/null || true
    install_git_confirmer
}

upgrade_git_confirmer() {
    if ! git_confirmer_repo_exists; then
        return 0
    fi

    if ! command_exists git; then
        return 0
    fi

    git -C "$GIT_CONFIRMER_INSTALL_DIR" fetch --quiet &>/dev/null || return 0

    local behind=0
    if git -C "$GIT_CONFIRMER_INSTALL_DIR" rev-parse --abbrev-ref --symbolic-full-name @{upstream} &>/dev/null; then
        behind=$(git -C "$GIT_CONFIRMER_INSTALL_DIR" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    else
        behind=1
    fi

    if [[ "$behind" -gt 0 ]]; then
        INSTALLED_SOMETHING=true
        echo -e "${SYMBOL_PACKAGE} Updating git_confirmer"
        if git -C "$GIT_CONFIRMER_INSTALL_DIR" pull --ff-only &>/dev/null; then
            if [[ -f "$GIT_CONFIRMER_INSTALL_DIR/install.sh" ]]; then
                bash "$GIT_CONFIRMER_INSTALL_DIR/install.sh" &>/dev/null && \
                    echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} git_confirmer updated" || \
                    echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to run git_confirmer installer"
            else
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} git_confirmer install.sh missing"
            fi
        else
            echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to update git_confirmer"
        fi
    fi
}
