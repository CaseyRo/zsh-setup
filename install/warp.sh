#!/bin/bash
# shellcheck shell=bash
# ============================================================================
# Warp terminal — standalone opt-in (macOS GUI machines only)
# ============================================================================
# Warp is offered as its own choice (prompt + --install-warp / --skip-warp),
# independent of the dev-machine profile and not bundled into the BREW_CASKS
# arrays — so it is never silently pulled in by a "yes" to generic casks and
# never skipped by --skip-casks.
#
# Beyond installing the app, this seeds Warp-specific config:
#   - the Cobalt2 theme (configs/warp/themes/Cobalt2.yaml → ~/.warp/themes/)
#   - a full starter settings.toml (appearance, vertical tabs, cursor, app
#     icon, ligatures, notifications, secret-redaction regexes, …) snapshotted
#     from a "looks cool" config (configs/warp/settings.toml) ONLY when none
#     exists yet; Warp rewrites settings.toml at runtime, so an existing one is
#     never clobbered. The __HOME__ placeholder is expanded to $HOME on seed.
# The Cascadia font cask is installed so the seeded font_name resolves.
# ============================================================================

WARP_THEME_SOURCE="$SCRIPT_DIR/configs/warp/themes/Cobalt2.yaml"
WARP_SETTINGS_SOURCE="$SCRIPT_DIR/configs/warp/settings.toml"

# Seed Warp config files. Safe to re-run.
seed_warp_config() {
    local warp_dir="$HOME/.warp"
    local themes_dir="$warp_dir/themes"
    local theme_target="$themes_dir/Cobalt2.yaml"
    local settings="$warp_dir/settings.toml"

    # --- Cobalt2 theme -----------------------------------------------------
    if [[ -f "$WARP_THEME_SOURCE" ]]; then
        mkdir -p "$themes_dir"
        if [[ -f "$theme_target" ]] && cmp -s "$WARP_THEME_SOURCE" "$theme_target"; then
            print_skip "Warp Cobalt2 theme"
            track_skipped "Warp Cobalt2 theme"
        else
            cp "$WARP_THEME_SOURCE" "$theme_target"
            print_success "Warp Cobalt2 theme seeded"
            track_installed "Warp Cobalt2 theme"
        fi
    else
        print_warning "Warp theme seed missing: $WARP_THEME_SOURCE"
        track_failed "Warp Cobalt2 theme"
    fi

    # --- settings.toml (full appearance config), only when absent ----------
    # Warp owns this file and rewrites it as the user changes preferences in
    # the GUI; we only provide a "looks cool" starting point on a fresh install.
    if [[ -f "$settings" ]]; then
        print_skip "Warp settings.toml (exists — left untouched)"
        track_skipped "Warp settings.toml"
        print_info "To apply manually: font 'Cascadia Code NF', theme 'Cobalt2', vertical tabs + 'aurora' icon in Warp → Settings → Appearance."
        return 0
    fi

    if [[ ! -f "$WARP_SETTINGS_SOURCE" ]]; then
        print_warning "Warp settings seed missing: $WARP_SETTINGS_SOURCE"
        track_failed "Warp settings.toml"
        return 0
    fi

    mkdir -p "$warp_dir"
    # Expand the __HOME__ placeholder to the real home dir for absolute theme
    # paths (sed '|' delimiter avoids clashing with slashes in $HOME).
    sed "s|__HOME__|$HOME|g" "$WARP_SETTINGS_SOURCE" > "$settings"
    print_success "Warp settings.toml seeded (full appearance: Cascadia Code NF + Cobalt2 + vertical tabs)"
    track_installed "Warp settings.toml"
}

install_warp() {
    # macOS GUI machines only, and only when the user opted in.
    if [[ "$OSTYPE" != "darwin"* ]] || ! has_display; then
        return 0
    fi
    if [[ "${INSTALL_WARP:-false}" != true ]]; then
        return 0
    fi

    print_section "Warp Terminal"

    # Warp app
    if brew list --cask "$WARP_CASK" &>/dev/null; then
        print_skip "$WARP_CASK"
        track_skipped "$WARP_CASK"
    else
        print_package "$WARP_CASK"
        if run_with_spinner "Installing $WARP_CASK" brew install --cask "$WARP_CASK"; then
            print_success "$WARP_CASK installed"
            track_installed "$WARP_CASK"
        else
            print_error "Failed to install $WARP_CASK"
            track_failed "$WARP_CASK"
            return 1
        fi
    fi

    # Cascadia font (provides the "Cascadia Code NF" family the seed selects)
    if brew list --cask "$WARP_FONT_CASK" &>/dev/null; then
        print_skip "$WARP_FONT_CASK"
        track_skipped "$WARP_FONT_CASK"
    else
        print_package "$WARP_FONT_CASK"
        if run_with_spinner "Installing $WARP_FONT_CASK" brew install --cask "$WARP_FONT_CASK"; then
            print_success "$WARP_FONT_CASK installed"
            track_installed "$WARP_FONT_CASK"
        else
            print_warning "Failed to install $WARP_FONT_CASK (Warp will fall back to a default font)"
            track_failed "$WARP_FONT_CASK"
        fi
    fi

    seed_warp_config
}
