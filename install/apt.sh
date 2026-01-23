# ============================================================================
# APT Installation (Debian/Ubuntu/Raspbian)
# ============================================================================
# Used on ARM Linux (Raspberry Pi) where Homebrew is slow

setup_apt_repos() {
    print_section "APT Repositories"

    # GitHub CLI repo
    if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
        print_step "Adding GitHub CLI repository"
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        print_success "GitHub CLI repo added"
        track_installed "GitHub CLI repository"
    else
        print_skip "GitHub CLI repository"
        track_skipped "GitHub CLI repository"
    fi

    # Docker repo (for non-macOS)
    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        print_step "Adding Docker repository"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        sudo chmod a+r /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        print_success "Docker repo added"
        track_installed "Docker repository"
    else
        print_skip "Docker repository"
        track_skipped "Docker repository"
    fi

    # Update package lists with 120s timeout to avoid hanging
    print_step "Updating package lists"
    (sudo apt-get update -qq &>/dev/null) &
    local pid=$!
    local count=0
    while kill -0 $pid 2>/dev/null && [[ $count -lt 120 ]]; do
        sleep 1
        ((count++))
    done
    if kill -0 $pid 2>/dev/null; then
        kill $pid 2>/dev/null
        wait $pid 2>/dev/null
        print_warning "apt update timed out (120s), continuing anyway"
    else
        wait $pid 2>/dev/null
        print_success "Package lists updated"
    fi
}

install_apt_packages() {
    print_section "APT Packages"

    for package in "${APT_PACKAGES[@]}"; do
        if dpkg -l "$package" &>/dev/null; then
            print_skip "$package"
            track_skipped "$package"
        else
            print_package "$package"
            if run_with_spinner "Installing $package" sudo apt-get install -y -qq "$package"; then
                print_success "$package installed"
                track_installed "$package"
            else
                print_error "Failed to install $package"
                track_failed "$package"
            fi
        fi
    done
}

install_docker_apt() {
    print_section "Docker"

    if command_exists docker; then
        print_skip "Docker"
        track_skipped "Docker"
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
        track_installed "Docker"
    fi
}

# Minimal cargo packages for ARM (only what's not in apt)
install_cargo_packages_minimal() {
    if [[ ${#CARGO_PACKAGES_ARM[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Cargo Packages (ARM-optimized)"
    print_info "Installing only packages not available via apt"
    print_info "Compiling from source - this may take several minutes per package on ARM"
    echo ""

    local total=${#CARGO_PACKAGES_ARM[@]}
    local current=0

    for package in "${CARGO_PACKAGES_ARM[@]}"; do
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
