#!/bin/bash
# ============================================================================
# Oh My Zsh Installation
# ============================================================================

install_oh_my_zsh() {
    print_section "Oh My Zsh"

    # Check ownership first
    if ! check_dir_ownership "$HOME/.oh-my-zsh" "Oh My Zsh"; then
        return 1
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_skip "Oh My Zsh"
        track_skipped "Oh My Zsh"
    else
        print_step "Installing Oh My Zsh"

        # Install without running zsh at the end (RUNZSH=no)
        # Don't replace .zshrc (KEEP_ZSHRC=yes) since we'll use our own
        if [[ "$VERBOSE" == true ]]; then
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        else
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &>/dev/null
        fi

        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            print_success "Oh My Zsh installed"
            track_installed "Oh My Zsh"
        else
            print_error "Oh My Zsh installation failed"
            track_failed "Oh My Zsh"
            return 1
        fi
    fi
}

install_zsh_plugins() {
    print_section "Zsh Plugins"

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

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

    # fast-syntax-highlighting (alternative, more performant)
    # if [[ -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]]; then
    #     print_skip "fast-syntax-highlighting"
    # else
    #     print_package "fast-syntax-highlighting"
    #     git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" &>/dev/null
    #     print_success "fast-syntax-highlighting installed"
    # fi
}
