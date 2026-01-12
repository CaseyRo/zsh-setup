# ============================================================================
# Tailscale Installation
# ============================================================================

install_tailscale() {
    print_section "Tailscale"

    if command_exists tailscale; then
        print_skip "Tailscale"
        return 0
    fi

    # On macOS, check if app is installed (cask doesn't add CLI to PATH immediately)
    if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/Applications/Tailscale.app" ]]; then
        print_skip "Tailscale (app installed, enable CLI in menu bar)"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Install via Homebrew cask
        print_step "Installing Tailscale (macOS app)"
        if run_with_spinner "Installing Tailscale" brew install --cask tailscale; then
            print_success "Tailscale installed"
        else
            print_error "Failed to install Tailscale"
            return 1
        fi
    else
        # Linux: Use official install script
        print_step "Installing Tailscale (Linux)"
        if curl -fsSL https://tailscale.com/install.sh | sh &>/dev/null; then
            print_success "Tailscale installed"
        else
            print_error "Failed to install Tailscale"
            return 1
        fi
    fi
}
