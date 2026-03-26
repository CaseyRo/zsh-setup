#!/bin/bash
# ============================================================================
# Zsh Plugin Installation (Starship-only, no Oh My Zsh)
# ============================================================================

install_oh_my_zsh() {
    # Oh My Zsh is no longer used — Starship is the only prompt
    return 0
}

install_zsh_plugins() {
    print_section "Zsh Plugins"

    local ZSH_CUSTOM="$HOME/.local/share/zsh-plugins"

    # zsh-autosuggestions
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        print_skip "zsh-autosuggestions"
        track_skipped "zsh-autosuggestions"
    else
        print_package "zsh-autosuggestions"
        if run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"; then
            print_success "zsh-autosuggestions installed"
            track_installed "zsh-autosuggestions"
        else
            print_error "Failed to install zsh-autosuggestions"
            track_failed "zsh-autosuggestions"
        fi
    fi

    # zsh-autocomplete
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]]; then
        print_skip "zsh-autocomplete"
        track_skipped "zsh-autocomplete"
    else
        print_package "zsh-autocomplete"
        if run_cmd git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"; then
            print_success "zsh-autocomplete installed"
            track_installed "zsh-autocomplete"
        else
            print_error "Failed to install zsh-autocomplete"
            track_failed "zsh-autocomplete"
        fi
    fi

    # zsh-syntax-highlighting
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        print_skip "zsh-syntax-highlighting"
        track_skipped "zsh-syntax-highlighting"
    else
        print_package "zsh-syntax-highlighting"
        if run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"; then
            print_success "zsh-syntax-highlighting installed"
            track_installed "zsh-syntax-highlighting"
        else
            print_error "Failed to install zsh-syntax-highlighting"
            track_failed "zsh-syntax-highlighting"
        fi
    fi
}
