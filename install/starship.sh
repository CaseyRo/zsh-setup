#!/bin/bash
# ============================================================================
# Starship Prompt Installation
# ============================================================================

# Fallback installer using the official starship.rs script. Downloads a
# prebuilt binary into /usr/local/bin without needing brew or cargo.
# Returns 0 on success, 1 on failure.
install_starship_prebuilt() {
    if ! command_exists curl; then
        return 1
    fi

    local tmp_script
    tmp_script=$(mktemp)
    if ! curl -fsSL https://starship.rs/install.sh -o "$tmp_script"; then
        rm -f "$tmp_script"
        return 1
    fi

    if run_with_spinner "Downloading Starship binary" sudo sh "$tmp_script" --yes --bin-dir /usr/local/bin; then
        rm -f "$tmp_script"
        return 0
    fi

    rm -f "$tmp_script"
    return 1
}

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
                print_error "Cargo install failed, trying official installer..."
                if install_starship_prebuilt; then
                    print_success "Starship installed (prebuilt)"
                    track_installed "Starship"
                else
                    print_error "Failed to install Starship"
                    track_failed "Starship"
                    return 1
                fi
            fi
        elif install_starship_prebuilt; then
            print_success "Starship installed (prebuilt)"
            track_installed "Starship"
        else
            print_error "Failed to install Starship"
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
