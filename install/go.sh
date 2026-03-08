#!/bin/bash
# ============================================================================
# Go Packages Installation
# ============================================================================

install_go_packages() {
    if [[ ${#GO_PACKAGES[@]} -eq 0 ]]; then
        return 0
    fi

    if ! command_exists go; then
        print_warning "Go not installed, skipping Go packages"
        return 0
    fi

    print_section "Go Packages"

    for package in "${GO_PACKAGES[@]}"; do
        # Extract binary name from the package path (last segment before @)
        local bin_name
        bin_name=$(basename "${package%%@*}")

        if command_exists "$bin_name"; then
            print_skip "$bin_name"
            track_skipped "$bin_name"
        else
            print_step "Installing $bin_name"
            if run_cmd go install "$package"; then
                print_success "$bin_name installed"
                track_installed "$bin_name"
            else
                print_error "Failed to install $bin_name"
                track_failed "$bin_name"
            fi
        fi
    done
}
