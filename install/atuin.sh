# shellcheck shell=bash
# ============================================================================
# Atuin Installation (Linux only — macOS uses Homebrew)
# ============================================================================

# Heal a lost +x on the atuin binaries. Seen in the wild after backup/restore
# or upstream self-update flows that rewrite the file without preserving mode.
# Cheap and idempotent; safe to call on every run.
ensure_atuin_executable() {
    local fixed=0
    local bin
    for bin in "$HOME/.atuin/bin/atuin" "$HOME/.atuin/bin/atuin-update"; do
        [[ -f "$bin" ]] || continue
        if [[ ! -x "$bin" ]]; then
            if chmod +x "$bin" 2>/dev/null; then
                fixed=$((fixed + 1))
            fi
        fi
    done
    if (( fixed > 0 )); then
        print_info "Restored +x on $fixed atuin binary/binaries in ~/.atuin/bin/"
    fi
}

install_atuin() {
    print_section "Atuin"

    if command_exists atuin; then
        print_skip "Atuin"
        track_skipped "Atuin"
        ensure_atuin_executable
        return 0
    fi

    print_step "Installing Atuin (shell history sync & search)"
    if curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
        ensure_atuin_executable
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
