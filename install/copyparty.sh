# shellcheck shell=bash
# ============================================================================
# Copyparty Installation
# ============================================================================
# Portable file server with resumable uploads, WebDAV, SFTP, FTP, and more
# https://github.com/9001/copyparty
# ============================================================================

# Ensure a build dependency is present; warn (don't fail) if it can't install.
# Usage: _copyparty_dep <cmd> <brew-pkg> <apt-pkg> <purpose>
_copyparty_dep() {
    local cmd="$1" brew_pkg="$2" apt_pkg="$3" purpose="$4"
    if command_exists "$cmd"; then
        print_skip "$cmd"
        track_skipped "$cmd"
        return 0
    fi
    print_step "Installing $cmd dependency"
    if command_exists brew; then
        if run_with_spinner "Installing $cmd" brew install "$brew_pkg"; then
            print_success "$cmd installed"; track_installed "$cmd"
        else
            print_warning "Failed to install $cmd. $purpose may not work."
        fi
    elif command_exists apt-get; then
        if run_with_spinner "Installing $cmd" sudo apt-get install -y "$apt_pkg"; then
            print_success "$cmd installed"; track_installed "$cmd"
        else
            print_warning "Failed to install $cmd. $purpose may not work."
        fi
    else
        print_warning "No supported package manager found. Install $cmd manually for $purpose."
    fi
}

install_copyparty() {
    print_section "Copyparty"

    _copyparty_dep ffmpeg ffmpeg ffmpeg "media transcoding"
    _copyparty_dep cfssl cfssl golang-cfssl "TLS certificate generation"

    if command_exists copyparty; then
        # Copyparty exists, but check if impacket is available for SMB support
        local copyparty_python=""

        # Find the Python interpreter for the copyparty installation
        if [[ -x "$HOME/.local/share/uv/tools/copyparty/bin/python3" ]]; then
            copyparty_python="$HOME/.local/share/uv/tools/copyparty/bin/python3"
        elif [[ -x "$HOME/.local/share/uv/tools/copyparty/bin/python" ]]; then
            copyparty_python="$HOME/.local/share/uv/tools/copyparty/bin/python"
        fi

        if [[ -n "$copyparty_python" ]]; then
            # Check if impacket is importable
            if ! "$copyparty_python" -c "import impacket" 2>/dev/null; then
                print_step "Installing missing SMB dependency (impacket)"
                if run_with_spinner "Installing impacket" uv tool install copyparty --with impacket --force; then
                    print_success "Copyparty SMB deps installed"
                    print_info "SMB default credentials: username 'a', password 'a'"
                    track_installed "Copyparty SMB deps (impacket)"
                else
                    print_warning "Failed to add impacket. SMB sharing may not work."
                    print_info "Install manually: uv tool install copyparty --with impacket --force"
                fi
            else
                print_skip "Copyparty (with SMB support)"
                track_skipped "Copyparty"
            fi
        else
            print_skip "Copyparty"
            track_skipped "Copyparty"
        fi
        return 0
    fi

    # Check if uv is available (preferred for uv-managed Python), otherwise use pipx/pip
    if command_exists uv; then
        print_step "Installing Copyparty via uv"

        # Clean up corrupted uv tool environment if it exists
        local uv_tool_dir="$HOME/.local/share/uv/tools/copyparty"
        if [[ -d "$uv_tool_dir" ]] && [[ ! -x "$uv_tool_dir/bin/python3" ]] && [[ ! -x "$uv_tool_dir/bin/python" ]]; then
            print_step "Cleaning up corrupted uv tool environment"
            rm -rf "$uv_tool_dir"
        fi

        # Use --force to handle cases where executable exists but command_exists failed
        # (e.g., executable in ~/.local/bin but not in PATH)
        if run_with_spinner "Installing Copyparty" uv tool install copyparty --with impacket --force; then
            print_success "Copyparty installed"
            print_info "SMB default credentials: username 'a', password 'a'"
            track_installed "Copyparty"
            return 0
        else
            print_warning "uv tool install failed, falling back to pipx"
        fi
    fi

    # Fallback to pipx if uv failed or wasn't available
    # Note: Direct pip install won't work on modern macOS due to PEP 668 (externally-managed-environment)
    if command_exists pipx; then
        print_step "Installing Copyparty via pipx"
        if run_with_spinner "Installing Copyparty" pipx install copyparty --force; then
            print_success "Copyparty installed"
            track_installed "Copyparty"
            if run_with_spinner "Installing Copyparty SMB deps (impacket)" pipx inject copyparty impacket; then
                print_success "Copyparty SMB deps installed"
                print_info "SMB default credentials: username 'a', password 'a'"
                track_installed "Copyparty SMB deps (impacket)"
            else
                print_warning "Copyparty SMB deps missing (impacket). SMB sharing may not work."
                print_info "Install manually: pipx inject copyparty impacket"
            fi
        else
            print_error "Failed to install Copyparty"
            track_failed "Copyparty"
            return 1
        fi
    else
        print_error "uv or pipx required for Copyparty installation"
        print_info "Install uv (brew install uv) or pipx (brew install pipx), then retry"
        track_failed "Copyparty (no uv/pipx)"
        return 0
    fi
}
