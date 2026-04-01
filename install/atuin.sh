# shellcheck shell=bash
# ============================================================================
# Atuin Installation (Linux only — macOS uses Homebrew)
# ============================================================================

install_atuin() {
    print_section "Atuin"

    if command_exists atuin; then
        print_skip "Atuin"
        track_skipped "Atuin"
        return 0
    fi

    print_step "Installing Atuin (shell history sync & search)"
    if curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
        print_success "Atuin installed"
        track_installed "Atuin"
    else
        print_error "Failed to install Atuin"
        track_failed "Atuin"
    fi
}

deploy_atuin_config() {
    local config_dir="$HOME/.config/atuin"
    local config_file="$config_dir/config.toml"
    local template="$SCRIPT_DIR/configs/atuin/config.toml"

    if [[ -f "$config_file" ]]; then
        print_skip "Atuin config (already exists)"
        track_skipped "Atuin config"
        return 0
    fi

    if [[ ! -f "$template" ]]; then
        return 0
    fi

    print_step "Deploying Atuin config template"
    mkdir -p "$config_dir"
    cp "$template" "$config_file"
    print_success "Atuin config deployed to $config_file"
    track_installed "Atuin config"
}
