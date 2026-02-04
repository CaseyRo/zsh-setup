# shellcheck shell=bash
# ============================================================================
# Mac App Store Installation (macOS only)
# ============================================================================

install_mas_apps() {
    # Only run on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        return 0
    fi

    if [[ "${SKIP_MAS_APPS:-false}" == true ]]; then
        print_section "Mac App Store Apps"
        print_skip "Mac App Store apps (skipped by user)"
        track_skipped "Mac App Store apps (skipped by user)"
        return 0
    fi

    if [[ ${#MAS_APPS[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Mac App Store Apps"

    # Install mas if not available
    if ! command_exists mas; then
        print_step "Installing mas (Mac App Store CLI)"
        if brew install mas &>/dev/null; then
            print_success "mas installed"
            track_installed "mas"
        else
            print_error "Failed to install mas, skipping App Store apps"
            track_failed "mas"
            return 1
        fi
    fi

    # Check if signed into App Store
    if ! mas account &>/dev/null; then
        print_warning "Not signed into App Store - please sign in via App Store.app"
        print_info "Skipping App Store apps (sign in and re-run to install)"
        return 0
    fi

    for app_id in "${MAS_APPS[@]}"; do
        local app_name
        app_name=$(mas info "$app_id" 2>/dev/null | head -1 | sed 's/ [0-9.]*$//' || echo "App $app_id")

        if mas list | grep -q "^$app_id "; then
            print_skip "$app_name"
            track_skipped "$app_name"
        else
            print_package "$app_name"
            if mas install "$app_id"; then
                print_success "$app_name installed"
                track_installed "$app_name"
            else
                print_error "Failed to install $app_name"
                track_failed "$app_name"
            fi
        fi
    done
}
