#!/bin/bash
# ============================================================================
# NVM & Node.js Installation
# ============================================================================

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
