# ============================================================================
# APT Installation (Debian/Ubuntu/Raspbian)
# ============================================================================
# Used on ARM Linux (Raspberry Pi) where Homebrew is slow

setup_apt_repos() {
    print_section "APT Repositories"

    # GitHub CLI repo
    if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
        print_step "Adding GitHub CLI repository"
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        print_success "GitHub CLI repo added"
    else
        print_skip "GitHub CLI repository"
    fi

    # Docker repo (for non-macOS)
    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        print_step "Adding Docker repository"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        sudo chmod a+r /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        print_success "Docker repo added"
    else
        print_skip "Docker repository"
    fi

    # Update package lists
    print_step "Updating package lists"
    run_with_spinner "Updating apt" sudo apt-get update -qq
    print_success "Package lists updated"
}

install_apt_packages() {
    print_section "APT Packages"

    for package in "${APT_PACKAGES[@]}"; do
        if dpkg -l "$package" &>/dev/null; then
            print_skip "$package"
        else
            print_package "$package"
            if run_with_spinner "Installing $package" sudo apt-get install -y -qq "$package"; then
                print_success "$package installed"
            else
                print_error "Failed to install $package"
            fi
        fi
    done
}

install_docker_apt() {
    print_section "Docker"

    if command_exists docker; then
        print_skip "Docker"
    else
        print_step "Installing Docker"
        local docker_packages=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
        for pkg in "${docker_packages[@]}"; do
            run_with_spinner "Installing $pkg" sudo apt-get install -y -qq "$pkg" || true
        done

        # Add current user to docker group
        if ! groups | grep -q docker; then
            print_step "Adding user to docker group"
            sudo usermod -aG docker "$USER"
            print_info "Log out and back in for docker group to take effect"
        fi

        print_success "Docker installed"
    fi
}

# Minimal cargo packages for ARM (only what's not in apt)
install_cargo_packages_minimal() {
    if [[ ${#CARGO_PACKAGES_ARM[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Cargo Packages (ARM-optimized)"
    print_info "Installing only packages not available via apt"

    for package in "${CARGO_PACKAGES_ARM[@]}"; do
        if cargo install --list | grep -q "^$package "; then
            print_skip "$package"
        else
            print_package "$package"
            if run_with_spinner "Installing $package" cargo install "$package"; then
                print_success "$package installed"
            else
                print_error "Failed to install $package"
            fi
        fi
    done
}
