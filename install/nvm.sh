#!/bin/bash
# ============================================================================
# NVM & Node.js Installation
# ============================================================================

install_nvm() {
    print_section "NVM (Node Version Manager)"

    export NVM_DIR="$HOME/.nvm"

    # Check ownership first
    if ! check_dir_ownership "$NVM_DIR" "NVM"; then
        return 1
    fi

    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        print_skip "NVM"
        track_skipped "NVM"
        # Load nvm for this session (|| true to prevent set -e exit)
        source "$NVM_DIR/nvm.sh" || true
    else
        print_step "Installing NVM"
        if [[ "$VERBOSE" == true ]]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        else
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh 2>/dev/null | bash &>/dev/null
        fi

        # Load nvm for this session
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh" || true
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
        [[ -s "$NVM_DIR/nvm.sh" ]] && { source "$NVM_DIR/nvm.sh" || true; }
    fi

    if ! command_exists nvm; then
        print_error "NVM not available, skipping Node.js installation"
        track_failed "Node.js (NVM not available)"
        return 1
    fi

    # Check if any node version is installed
    if nvm list 2>/dev/null | grep -q "v[0-9]"; then
        local current_version=$(nvm current 2>/dev/null)
        if [[ -z "$current_version" || "$current_version" == "none" || "$current_version" == "system" ]]; then
            # No version active, try to activate and set default
            nvm use node &>/dev/null || true
            nvm alias default node &>/dev/null || true
            current_version=$(nvm current 2>/dev/null)
        fi
        # If still no active version, force reinstall
        if [[ -z "$current_version" || "$current_version" == "none" ]]; then
            print_step "Reinstalling Node.js (activation failed)"
            nvm install node
            nvm use node
            nvm alias default node
            current_version=$(nvm current 2>/dev/null)
        fi
        if [[ -n "$current_version" && "$current_version" != "none" ]]; then
            print_skip "Node.js ($current_version)"
            track_skipped "Node.js ($current_version)"
        else
            print_error "Node.js activation failed"
            track_failed "Node.js"
            return 1
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
    # Check npm cache directory ownership
    if [[ -d "$HOME/.npm" ]]; then
        if ! check_dir_ownership "$HOME/.npm" "npm cache"; then
            return 1
        fi
    fi

    # Build package list
    local packages=("${NPM_GLOBAL_PACKAGES[@]}")

    # Add host-only packages (pm2, node-red) when not in Docker
    if ! is_docker; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if [[ "${ALLOW_MAC_NETWORKED_SERVICES:-false}" == true ]]; then
                packages+=("${NPM_GLOBAL_PACKAGES_HOST[@]}")
            else
                for package in "${NPM_GLOBAL_PACKAGES_HOST[@]}"; do
                    print_skip "$package (macOS networked services disabled)"
                    track_skipped "$package (macOS networked services disabled)"
                done
            fi
        else
            packages+=("${NPM_GLOBAL_PACKAGES_HOST[@]}")
        fi
    fi

    # In light mode, filter out heavy/unnecessary npm packages
    if [[ "$LIGHT_MODE" == true ]]; then
        local _npm_light_skip="node-red"
        local filtered=()
        for package in "${packages[@]}"; do
            if [[ " $_npm_light_skip " == *" $package "* ]]; then
                print_skip "$package (light mode)"
                track_skipped "$package (light mode)"
            else
                filtered+=("$package")
            fi
        done
        packages=("${filtered[@]}")
    fi

    if [[ "$LIGHT_MODE" != true ]] && { [[ "$OSTYPE" == "darwin"* ]] || is_ubuntu || is_debian; }; then
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
