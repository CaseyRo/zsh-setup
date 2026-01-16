# ============================================================================
# Copyparty Installation
# ============================================================================
# Portable file server with resumable uploads, WebDAV, SFTP, FTP, and more
# https://github.com/9001/copyparty
# ============================================================================

install_copyparty() {
    print_section "Copyparty"

    if command_exists copyparty; then
        print_skip "Copyparty"
        track_skipped "Copyparty"
        return 0
    fi

    # Check if uv is available (preferred for uv-managed Python), otherwise use pipx/pip
    if command_exists uv; then
        print_step "Installing Copyparty via uv"
        if run_with_spinner "Installing Copyparty" uv tool install copyparty; then
            print_success "Copyparty installed"
            track_installed "Copyparty"
        elif run_with_spinner "Installing Copyparty (uv pip)" uv pip install --user copyparty; then
            print_success "Copyparty installed"
            track_installed "Copyparty"
        else
            print_error "Failed to install Copyparty"
            track_failed "Copyparty"
            return 1
        fi
    elif command_exists pipx; then
        print_step "Installing Copyparty via pipx"
        if run_with_spinner "Installing Copyparty" pipx install copyparty; then
            print_success "Copyparty installed"
            track_installed "Copyparty"
        else
            print_error "Failed to install Copyparty"
            track_failed "Copyparty"
            return 1
        fi
    elif command_exists pip3; then
        print_step "Installing Copyparty via pip3"
        if run_with_spinner "Installing Copyparty" pip3 install --user copyparty; then
            print_success "Copyparty installed"
            track_installed "Copyparty"
        else
            print_error "Failed to install Copyparty"
            track_failed "Copyparty"
            return 1
        fi
    elif command_exists pip; then
        print_step "Installing Copyparty via pip"
        if run_with_spinner "Installing Copyparty" pip install --user copyparty; then
            print_success "Copyparty installed"
            track_installed "Copyparty"
        else
            print_error "Failed to install Copyparty"
            track_failed "Copyparty"
            return 1
        fi
    else
        print_error "Python/pip not found - skipping Copyparty"
        print_info "Install Python first, then run: pip install copyparty"
        track_failed "Copyparty (no pip)"
        return 0
    fi
}
