# shellcheck shell=bash
# ============================================================================
# macOS Desktop Automations (macOS only)
# ============================================================================
# Clones/updates the macos-automations repo and runs its installer.
# Pattern matches git_confirmer — separate repo, pulled at install time.
# ============================================================================

MACOS_AUTOMATIONS_REPO_URL="https://github.com/CaseyRo/macos-automations.git"
MACOS_AUTOMATIONS_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/macos-automations"

macos_automations_repo_exists() {
    [[ -d "$MACOS_AUTOMATIONS_INSTALL_DIR/.git" ]]
}

macos_automations_clone_or_update() {
    mkdir -p "$(dirname "$MACOS_AUTOMATIONS_INSTALL_DIR")"

    if macos_automations_repo_exists; then
        run_with_spinner "Updating macos-automations repo" \
            git -C "$MACOS_AUTOMATIONS_INSTALL_DIR" pull --ff-only
        return $?
    fi

    run_with_spinner "Cloning macos-automations repo" \
        git clone "$MACOS_AUTOMATIONS_REPO_URL" "$MACOS_AUTOMATIONS_INSTALL_DIR"
}

install_macos_automations() {
    # macOS only
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 0
    fi

    print_section "macOS Desktop Automations"

    if ! command_exists git; then
        print_error "git is required to install macos-automations"
        track_failed "macos-automations"
        return 1
    fi

    # Clone or update the repo
    if ! macos_automations_clone_or_update; then
        print_error "Failed to download macos-automations"
        track_failed "macos-automations"
        return 1
    fi

    # Run the repo's own installer
    if [[ ! -f "$MACOS_AUTOMATIONS_INSTALL_DIR/install.sh" ]]; then
        print_error "macos-automations install.sh not found"
        track_failed "macos-automations"
        return 1
    fi

    if bash "$MACOS_AUTOMATIONS_INSTALL_DIR/install.sh"; then
        track_installed "macos-automations"

        if ui_confirm "Open Desktop Automations dashboard now?"; then
            open "http://localhost:7820"
        fi
    else
        print_error "macos-automations installation failed"
        track_failed "macos-automations"
        return 1
    fi
}

upgrade_macos_automations() {
    # macOS only
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 0
    fi

    if ! macos_automations_repo_exists; then
        return 0
    fi

    if ! command_exists git; then
        return 0
    fi

    git -C "$MACOS_AUTOMATIONS_INSTALL_DIR" fetch --quiet &>/dev/null || return 0

    local behind=0
    if git -C "$MACOS_AUTOMATIONS_INSTALL_DIR" rev-parse --abbrev-ref --symbolic-full-name @{upstream} &>/dev/null; then
        behind=$(git -C "$MACOS_AUTOMATIONS_INSTALL_DIR" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    else
        behind=1
    fi

    if [[ "$behind" -gt 0 ]]; then
        INSTALLED_SOMETHING=true
        echo -e "${SYMBOL_PACKAGE} Updating macos-automations"
        if git -C "$MACOS_AUTOMATIONS_INSTALL_DIR" pull --ff-only &>/dev/null; then
            if bash "$MACOS_AUTOMATIONS_INSTALL_DIR/install.sh" &>/dev/null; then
                echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} macos-automations updated"
            else
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to run macos-automations installer"
            fi
        else
            echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to update macos-automations"
        fi
    fi
}
