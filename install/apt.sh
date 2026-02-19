# shellcheck shell=bash
# ============================================================================
# APT Installation (Debian/Ubuntu/Raspbian)
# ============================================================================
# Used on Debian/Ubuntu Linux where APT is the native package manager

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

    # Update package lists
    print_step "Updating package lists"
    if sudo apt-get update -qq; then
        print_success "Package lists updated"
    else
        print_warning "apt update failed, continuing anyway"
    fi
}

install_apt_packages() {
    print_section "APT Packages"

    for package in "${APT_PACKAGES[@]}"; do
        # Use dpkg -s to check if package is actually installed (not just known)
        if dpkg -s "$package" &>/dev/null; then
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

install_apt_packages_ubuntu() {
    # Skip if not Ubuntu or no Ubuntu-specific packages
    if ! is_ubuntu || [[ ${#APT_PACKAGES_UBUNTU[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Ubuntu-specific Packages"

    for package in "${APT_PACKAGES_UBUNTU[@]}"; do
        if dpkg -s "$package" &>/dev/null; then
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

    # Enable and start cockpit if installed
    if dpkg -s cockpit &>/dev/null; then
        if systemctl is-active --quiet cockpit.socket; then
            print_skip "cockpit service (already running)"
        else
            print_step "Enabling cockpit service"
            if sudo systemctl enable --now cockpit.socket &>/dev/null; then
                print_success "Cockpit enabled and running on port 9090"
                track_installed "cockpit service"
            else
                print_error "Failed to enable cockpit service"
                track_failed "cockpit service"
            fi
        fi
    fi
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
        print_success "Docker installed"
        track_installed "Docker"
    fi

    # Always ensure user is in docker group (even if Docker was already installed)
    if command_exists docker && ! groups | grep -q docker; then
        print_step "Adding user to docker group"
        sudo usermod -aG docker "$USER"
        print_info "Log out and back in for docker group to take effect"
        track_installed "docker group membership"
    fi
}

install_fastfetch_apt() {
    print_section "Fastfetch"

    if command_exists fastfetch; then
        print_skip "Fastfetch"
        track_skipped "Fastfetch"
        return 0
    fi

    print_package "fastfetch"

    local arch
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="aarch64" ;;
        armv7l)  arch="armv7l" ;;
        *)
            print_error "Unsupported architecture for Fastfetch: $(uname -m)"
            track_failed "Fastfetch"
            return 1
            ;;
    esac

    local version
    version=$(curl -fsSL "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest Fastfetch version"
        track_failed "Fastfetch"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/fastfetch-linux-${arch}.deb"

    if run_with_spinner "Downloading Fastfetch ${version}" curl -fsSL "$url" -o "${tmp_dir}/fastfetch.deb" && \
       sudo dpkg -i "${tmp_dir}/fastfetch.deb" &>/dev/null; then
        print_success "Fastfetch ${version} installed"
        track_installed "Fastfetch"
    else
        print_error "Failed to install Fastfetch"
        track_failed "Fastfetch"
    fi

    rm -rf "$tmp_dir"
}

# Minimal cargo packages for APT systems (only what's not in apt)
install_cargo_packages_minimal() {
    if [[ ${#CARGO_PACKAGES_APT[@]} -eq 0 ]]; then
        return 0
    fi

    # Check cargo ownership and permissions before proceeding
    if ! check_dir_ownership "$HOME/.cargo" "Cargo"; then
        print_error "Cannot install cargo packages - fix ownership first"
        for package in "${CARGO_PACKAGES_APT[@]}"; do
            track_failed "$package"
        done
        return 1
    fi
    if ! check_binary_executable "$HOME/.cargo/bin/cargo" "cargo"; then
        print_error "Cannot install cargo packages - fix permissions first"
        for package in "${CARGO_PACKAGES_APT[@]}"; do
            track_failed "$package"
        done
        return 1
    fi

    print_section "Cargo Packages (APT supplement)"
    print_info "Installing only packages not available via apt"
    print_info "Compiling from source - this may take several minutes per package"
    echo ""

    local total=${#CARGO_PACKAGES_APT[@]}
    local current=0

    for package in "${CARGO_PACKAGES_APT[@]}"; do
        current=$((current + 1))
        if cargo install --list | grep -q "^$package "; then
            print_skip "$package"
            track_skipped "$package"
        else
            echo -e "  ${SYMBOL_PACKAGE} ${BOLD}[$current/$total]${RESET} Compiling ${BOLD}$package${RESET}..."
            echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
            local install_output
            local install_status
            install_output=$(cargo install "$package" 2>&1) && install_status=0 || install_status=$?
            echo "$install_output" | sed 's/^/    /'
            echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
            if [[ $install_status -eq 0 ]]; then
                print_success "$package installed"
                track_installed "$package"
            else
                print_error "Failed to install $package"
                track_failed "$package"
            fi
            echo ""
        fi
    done
}
