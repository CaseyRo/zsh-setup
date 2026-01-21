# ============================================================================
# Copyparty Installation
# ============================================================================
# Portable file server with resumable uploads, WebDAV, SFTP, FTP, and more
# https://github.com/9001/copyparty
# ============================================================================

install_copyparty() {
    print_section "Copyparty"

    # Install ffmpeg dependency (required for media transcoding)
    if ! command_exists ffmpeg; then
        print_step "Installing ffmpeg dependency"
        if command_exists brew; then
            if run_with_spinner "Installing ffmpeg" brew install ffmpeg; then
                print_success "ffmpeg installed"
                track_installed "ffmpeg"
            else
                print_warning "Failed to install ffmpeg. Media transcoding may not work."
            fi
        elif command_exists apt-get; then
            if run_with_spinner "Installing ffmpeg" sudo apt-get install -y ffmpeg; then
                print_success "ffmpeg installed"
                track_installed "ffmpeg"
            else
                print_warning "Failed to install ffmpeg. Media transcoding may not work."
            fi
        else
            print_warning "No supported package manager found. Install ffmpeg manually for media transcoding."
        fi
    else
        print_skip "ffmpeg"
        track_skipped "ffmpeg"
    fi

    # Install cfssl dependency (required for TLS certificate generation)
    if ! command_exists cfssl; then
        print_step "Installing cfssl dependency"
        if command_exists brew; then
            if run_with_spinner "Installing cfssl" brew install cfssl; then
                print_success "cfssl installed"
                track_installed "cfssl"
            else
                print_warning "Failed to install cfssl. TLS certificate generation may not work."
            fi
        elif command_exists apt-get; then
            if run_with_spinner "Installing cfssl" sudo apt-get install -y golang-cfssl; then
                print_success "cfssl installed"
                track_installed "cfssl"
            else
                print_warning "Failed to install cfssl. TLS certificate generation may not work."
            fi
        else
            print_warning "No supported package manager found. Install cfssl manually for TLS certificates."
        fi
    else
        print_skip "cfssl"
        track_skipped "cfssl"
    fi

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
