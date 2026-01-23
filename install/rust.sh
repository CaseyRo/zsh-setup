#!/bin/bash
# ============================================================================
# Rust & Cargo Installation
# ============================================================================

install_rust() {
    print_section "Rust"

    if command_exists rustc && command_exists cargo; then
        print_skip "Rust/Cargo"
        track_skipped "Rust"
        print_step "Updating Rust"

        # Run rustup update with 60s timeout to avoid hanging
        local timeout_cmd=""
        if command -v timeout &>/dev/null; then
            timeout_cmd="timeout 60"
        elif command -v gtimeout &>/dev/null; then
            timeout_cmd="gtimeout 60"
        fi

        if [[ -n "$timeout_cmd" ]]; then
            if $timeout_cmd rustup update &>/dev/null; then
                print_success "Rust updated"
            else
                local exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    print_warning "Rust update timed out (60s), skipping"
                else
                    print_warning "Rust update failed, continuing anyway"
                fi
            fi
        else
            # No timeout command available, run directly
            if rustup update &>/dev/null; then
                print_success "Rust updated"
            else
                print_warning "Rust update failed, continuing anyway"
            fi
        fi
    else
        print_step "Installing Rust via rustup"
        if [[ "$VERBOSE" == true ]]; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
        fi

        # Add cargo to PATH for this session
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
        fi

        if command_exists cargo; then
            print_success "Rust installed"
            track_installed "Rust"
        else
            print_error "Rust installation failed"
            track_failed "Rust"
            return 1
        fi
    fi
}

install_cargo_packages() {
    if [[ ${#CARGO_PACKAGES[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Cargo Packages"
    print_info "Compiling from source - this may take several minutes per package"
    echo ""

    local total=${#CARGO_PACKAGES[@]}
    local current=0

    for package in "${CARGO_PACKAGES[@]}"; do
        current=$((current + 1))
        if cargo install --list | grep -q "^$package "; then
            print_skip "$package"
            track_skipped "$package"
        else
            echo -e "  ${SYMBOL_PACKAGE} ${BOLD}[$current/$total]${RESET} Compiling ${BOLD}$package${RESET}..."
            echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
            if cargo install "$package" 2>&1 | sed 's/^/    /'; then
                echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
                print_success "$package installed"
                track_installed "$package"
            else
                echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
                print_error "Failed to install $package"
                track_failed "$package"
            fi
            echo ""
        fi
    done
}
