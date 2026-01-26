# shellcheck shell=bash
# ============================================================================
# Tailscale Installation & Configuration
# ============================================================================

# Configure Tailscale with user preferences (SSH, MagicDNS)
configure_tailscale() {
    # Skip if Tailscale is not installed
    if ! command_exists tailscale; then
        return 0
    fi

    # Skip on macOS (configured via GUI)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        return 0
    fi

    # Check if already connected
    if tailscale status &>/dev/null; then
        print_skip "Tailscale (already configured)"
        return 0
    fi

    print_section "Tailscale Configuration"
    print_info "Configure Tailscale connection settings"
    echo ""

    # Build tailscale up command with options
    local ts_args=()

    # SSH access
    if ui_confirm "Enable Tailscale SSH? (access this machine via 'tailscale ssh')"; then
        ts_args+=("--ssh")
        print_info "SSH access will be enabled"
    else
        print_info "SSH access will be disabled"
    fi

    # MagicDNS
    if ui_confirm "Enable MagicDNS? (use Tailscale for DNS - may conflict with Docker)"; then
        ts_args+=("--accept-dns=true")
        print_info "MagicDNS will be enabled"
    else
        ts_args+=("--accept-dns=false")
        print_info "MagicDNS will be disabled (recommended if using Docker)"
    fi

    echo ""
    print_step "Starting Tailscale"
    print_info "A browser window will open for authentication"
    echo ""

    # Run tailscale up with collected options
    if sudo tailscale up "${ts_args[@]}"; then
        print_success "Tailscale configured and connected"
        track_installed "Tailscale configuration"
    else
        print_warning "Tailscale setup incomplete - run 'sudo tailscale up' manually"
    fi
}

install_tailscale() {
    print_section "Tailscale"

    if command_exists tailscale; then
        print_skip "Tailscale"
        track_skipped "Tailscale"
        return 0
    fi

    # On macOS, check if app is installed (cask doesn't add CLI to PATH immediately)
    if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/Applications/Tailscale.app" ]]; then
        print_skip "Tailscale (app installed, enable CLI in menu bar)"
        track_skipped "Tailscale"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Install via Homebrew cask
        print_step "Installing Tailscale (macOS app)"
        if run_with_spinner "Installing Tailscale" brew install --cask tailscale; then
            print_success "Tailscale installed"
            track_installed "Tailscale"
        else
            print_error "Failed to install Tailscale"
            track_failed "Tailscale"
            return 1
        fi
    else
        # Linux: Use official install script
        print_step "Installing Tailscale (Linux)"
        if [[ "$VERBOSE" == true ]]; then
            curl -fsSL https://tailscale.com/install.sh | sh
        else
            curl -fsSL https://tailscale.com/install.sh | sh &>/dev/null
        fi
        if command_exists tailscale; then
            print_success "Tailscale installed"
            track_installed "Tailscale"
        else
            print_error "Failed to install Tailscale"
            track_failed "Tailscale"
            return 1
        fi
    fi
}
