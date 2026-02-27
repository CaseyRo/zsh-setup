#!/bin/bash
# ============================================================================
# Homebrew Installation
# ============================================================================

install_homebrew() {
    print_section "Homebrew"

    if command_exists brew; then
        print_skip "Homebrew"
        track_skipped "Homebrew"
        print_step "Updating Homebrew"
        if brew update; then
            print_success "Homebrew updated"
        else
            print_warning "Homebrew update failed, continuing anyway"
        fi
    else
        local has_sudo=false
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if sudo -n true 2>/dev/null; then
                has_sudo=true
            fi
        fi

        if [[ "$OSTYPE" == "darwin"* ]] && [[ "$has_sudo" == false ]]; then
            local brew_prefix="$HOME/homebrew"
            print_step "Installing Homebrew (user-space)"
            mkdir -p "$brew_prefix"
            if [[ "$VERBOSE" == true ]]; then
                curl -fsSL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$brew_prefix"
            else
                curl -fsSL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$brew_prefix" &>/dev/null
            fi
            export PATH="$brew_prefix/bin:$PATH"
            print_info "User-space Homebrew installed at $brew_prefix"
            print_info "Add to PATH: export PATH=\"$brew_prefix/bin:\$PATH\""
        else
            print_step "Installing Homebrew"
            if [[ "$VERBOSE" == true ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
            fi

            # Add brew to PATH for this session (macOS ARM)
            if [[ "$OSTYPE" == "darwin"* ]] && [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi

        if command_exists brew; then
            print_success "Homebrew installed"
            track_installed "Homebrew"
        else
            print_error "Homebrew installation failed"
            track_failed "Homebrew"
            return 1
        fi
    fi
}

install_brew_taps() {
    if [[ ${#BREW_TAPS[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Brew Taps"

    for tap in "${BREW_TAPS[@]}"; do
        if brew tap | grep -qx "$tap"; then
            print_skip "$tap"
            track_skipped "$tap"
        else
            print_package "$tap"
            if run_with_spinner "Tapping $tap" brew tap "$tap"; then
                print_success "$tap tapped"
                track_installed "$tap"
            else
                print_error "Failed to tap $tap"
                track_failed "$tap"
            fi
        fi
    done
}

install_brew_packages() {
    print_section "Brew Packages"

    for package in "${BREW_PACKAGES[@]}"; do
        if brew list "$package" &>/dev/null; then
            print_skip "$package"
            track_skipped "$package"
        else
            print_package "$package"
            if run_with_spinner "Installing $package" brew install "$package"; then
                print_success "$package installed"
                track_installed "$package"
            else
                print_error "Failed to install $package"
                track_failed "$package"
            fi
        fi
    done
}

install_brew_packages_mac_dev() {
    # macOS dev machines only
    if [[ "$OSTYPE" != "darwin"* ]] || [[ "${IS_MAC_DEV_MACHINE:-false}" != true ]]; then
        return 0
    fi

    if [[ ${#BREW_PACKAGES_MAC_DEV[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Brew Packages (macOS Dev Machine)"

    for package in "${BREW_PACKAGES_MAC_DEV[@]}"; do
        if brew list "$package" &>/dev/null; then
            print_skip "$package"
            track_skipped "$package"
        else
            print_package "$package"
            if run_with_spinner "Installing $package" brew install "$package"; then
                print_success "$package installed"
                track_installed "$package"
            else
                print_error "Failed to install $package"
                track_failed "$package"
            fi
        fi
    done
}

install_brew_casks() {
    # Only run on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 0
    fi

    if [[ "${SKIP_BREW_CASKS:-false}" == true ]]; then
        print_section "Brew Casks (macOS Apps)"
        print_skip "Brew casks (skipped by user)"
        track_skipped "Brew casks (skipped by user)"
        return 0
    fi

    if [[ ${#BREW_CASKS[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Brew Casks (macOS Apps)"

    for cask in "${BREW_CASKS[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            print_skip "$cask"
            track_skipped "$cask"
        else
            print_package "$cask"
            if run_with_spinner "Installing $cask" brew install --cask "$cask"; then
                print_success "$cask installed"
                track_installed "$cask"
            else
                print_error "Failed to install $cask"
                track_failed "$cask"
            fi
        fi
    done
}

install_brew_casks_mac_dev() {
    # macOS dev machines only
    if [[ "$OSTYPE" != "darwin"* ]] || [[ "${IS_MAC_DEV_MACHINE:-false}" != true ]]; then
        return 0
    fi

    if [[ "${SKIP_BREW_CASKS:-false}" == true ]]; then
        print_section "Brew Casks (macOS Dev Machine)"
        print_skip "Brew dev casks (skipped by user)"
        track_skipped "Brew dev casks (skipped by user)"
        return 0
    fi

    if [[ ${#BREW_CASKS_MAC_DEV[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Brew Casks (macOS Dev Machine)"

    for cask in "${BREW_CASKS_MAC_DEV[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            print_skip "$cask"
            track_skipped "$cask"
        else
            print_package "$cask"
            if run_with_spinner "Installing $cask" brew install --cask "$cask"; then
                print_success "$cask installed"
                track_installed "$cask"
            else
                print_error "Failed to install $cask"
                track_failed "$cask"
            fi
        fi
    done
}
