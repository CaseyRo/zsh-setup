#!/bin/bash
# ============================================================================
# Starship Prompt Installation
# ============================================================================

install_starship() {
    print_section "Starship Prompt"

    if command_exists starship; then
        print_skip "Starship"
        track_skipped "Starship"
    else
        print_step "Installing Starship"

        if command_exists brew; then
            if run_cmd brew install starship; then
                print_success "Starship installed (Homebrew)"
                track_installed "Starship"
            else
                print_error "Homebrew install failed, trying cargo..."
                if command_exists cargo && run_cmd cargo install starship; then
                    print_success "Starship installed (Cargo)"
                    track_installed "Starship"
                else
                    print_error "Failed to install Starship"
                    track_failed "Starship"
                    return 1
                fi
            fi
        elif command_exists cargo; then
            if run_cmd cargo install starship; then
                print_success "Starship installed (Cargo)"
                track_installed "Starship"
            else
                print_error "Failed to install Starship"
                track_failed "Starship"
                return 1
            fi
        else
            print_error "No package manager available for Starship (need brew or cargo)"
            track_failed "Starship"
            return 1
        fi
    fi

    # Symlink starship config
    local STARSHIP_CONFIG_DIR="$HOME/.config"
    local STARSHIP_TARGET="$STARSHIP_CONFIG_DIR/starship.toml"
    local STARSHIP_SOURCE="$SCRIPT_DIR/configs/starship.toml"

    if [[ -L "$STARSHIP_TARGET" ]] && [[ "$(readlink "$STARSHIP_TARGET")" == "$STARSHIP_SOURCE" ]]; then
        print_skip "starship config symlink"
        track_skipped "starship config"
    else
        mkdir -p "$STARSHIP_CONFIG_DIR"

        if [[ -f "$STARSHIP_TARGET" ]] || [[ -L "$STARSHIP_TARGET" ]]; then
            print_step "Backing up existing starship.toml"
            mv "$STARSHIP_TARGET" "$STARSHIP_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            print_success "Backup created"
        fi

        print_step "Creating starship config symlink"
        ln -s "$STARSHIP_SOURCE" "$STARSHIP_TARGET"
        print_success "\$HOME/.config/starship.toml → $STARSHIP_SOURCE"
        track_installed "starship config"
    fi
}
