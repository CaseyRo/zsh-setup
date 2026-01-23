#!/bin/bash
# ============================================================================
# NVM & Node.js Installation
# ============================================================================

install_nvm() {
    print_section "NVM (Node Version Manager)"

    export NVM_DIR="$HOME/.nvm"

    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        print_skip "NVM"
        track_skipped "NVM"
        # Load nvm for this session
        source "$NVM_DIR/nvm.sh"
    else
        print_step "Installing NVM"
        if [[ "$VERBOSE" == true ]]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        else
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh 2>/dev/null | bash &>/dev/null
        fi

        # Load nvm for this session
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh"
            print_success "NVM installed"
            track_installed "NVM"
        else
            print_error "NVM installation failed"
            track_failed "NVM"
            return 1
        fi
    fi
}

install_node() {
    print_section "Node.js"

    if ! command_exists nvm; then
        # Try loading nvm
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    fi

    if ! command_exists nvm; then
        print_error "NVM not available, skipping Node.js installation"
        track_failed "Node.js (NVM not available)"
        return 1
    fi

    # Check if any node version is installed
    if nvm list 2>/dev/null | grep -q "v[0-9]"; then
        local current_version=$(nvm current 2>/dev/null)
        print_skip "Node.js ($current_version)"
        print_step "Checking for updates"

        # Check if there's a newer stable version (with 10s timeout to avoid hanging)
        local latest_stable=""
        local tmpfile=$(mktemp)
        (nvm version-remote node > "$tmpfile" 2>/dev/null) &
        local pid=$!
        local count=0
        while kill -0 $pid 2>/dev/null && [[ $count -lt 10 ]]; do
            sleep 1
            ((count++))
        done
        if kill -0 $pid 2>/dev/null; then
            kill $pid 2>/dev/null
            wait $pid 2>/dev/null
            print_warning "Update check timed out, skipping"
        else
            wait $pid 2>/dev/null
            latest_stable=$(cat "$tmpfile" 2>/dev/null)
        fi
        rm -f "$tmpfile"
        if [[ "$current_version" != "$latest_stable" ]] && [[ -n "$latest_stable" ]]; then
            local latest_installed
            latest_installed=$(nvm version "$latest_stable" 2>/dev/null)
            if [[ "$latest_installed" != "N/A" ]]; then
                print_info "Latest stable already installed: $latest_stable"
                run_cmd nvm use node
                run_cmd nvm alias default node
                print_success "Already on latest stable"
                track_skipped "Node.js ($latest_stable)"
            else
                print_info "Newer stable available: $latest_stable"
                print_step "Installing Node.js $latest_stable"
                run_cmd nvm install node
                run_cmd nvm use node
                run_cmd nvm alias default node
                print_success "Node.js updated to $latest_stable"
                track_installed "Node.js $latest_stable"
            fi
        else
            print_success "Already on latest stable"
            track_skipped "Node.js ($current_version)"
        fi
    else
        print_step "Installing Node.js stable"
        if [[ "$VERBOSE" == true ]]; then
            nvm install node
            nvm use node
            nvm alias default node
        else
            nvm install node &>/dev/null
            nvm use node &>/dev/null
            nvm alias default node &>/dev/null
        fi

        if command_exists node; then
            print_success "Node.js $(node --version) installed"
            track_installed "Node.js $(node --version)"
        else
            print_error "Node.js installation failed"
            track_failed "Node.js"
            return 1
        fi
    fi
}

install_npm_global_packages() {
    # Build package list - add desktop packages for macOS/Ubuntu
    local packages=("${NPM_GLOBAL_PACKAGES[@]}")
    if [[ "$OSTYPE" == "darwin"* ]] || is_ubuntu; then
        packages+=("${NPM_GLOBAL_PACKAGES_DESKTOP[@]}")
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Global npm Packages"

    if ! command_exists npm; then
        print_error "npm not available, skipping global packages"
        for package in "${packages[@]}"; do
            track_failed "$package (npm not available)"
        done
        return 1
    fi

    for package in "${packages[@]}"; do
        if npm list -g "$package" &>/dev/null; then
            print_skip "$package"
            track_skipped "$package"
        else
            print_package "$package"
            if run_with_spinner "Installing $package" npm install -g "$package"; then
                print_success "$package installed"
                track_installed "$package"
            else
                print_error "Failed to install $package"
                track_failed "$package"
            fi
        fi
    done
}
