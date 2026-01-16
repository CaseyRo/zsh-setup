#!/bin/bash
# ============================================================================
# Lazygit Installation
# ============================================================================

install_lazygit() {
    print_section "Lazygit"

    if command_exists lazygit; then
        print_skip "Lazygit"
        track_skipped "Lazygit"
        return 0
    fi

    if ! command_exists brew; then
        print_error "Homebrew not found (required for Lazygit install)"
        track_failed "Lazygit"
        return 1
    fi

    print_package "lazygit"
    if run_with_spinner "Installing Lazygit" brew install "lazygit"; then
        print_success "Lazygit installed"
        track_installed "Lazygit"
    else
        print_error "Failed to install Lazygit"
        track_failed "Lazygit"
    fi
}
