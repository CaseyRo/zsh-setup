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
#   - the Cobalt2 themes (configs/warp/themes/*.yaml → ~/.warp/themes/); the
#     seeded settings.toml defaults to "Cobalt2 Dim" — a lower-contrast variant
#     (off-white fg instead of pure #fff) that avoids halation/eye-strain on
#     high-density Retina displays. Plain "Cobalt2" ships too, switchable in-GUI.
#   - a full starter settings.toml (appearance, vertical tabs, cursor, app
#     icon, ligatures, notifications, secret-redaction regexes, …) snapshotted
#     from a "looks cool" config (configs/warp/settings.toml) ONLY when none
#     exists yet; Warp rewrites settings.toml at runtime, so an existing one is
#     never clobbered. The __HOME__ placeholder is expanded to $HOME on seed.
# The Cascadia font cask is installed so the seeded font_name resolves, and
# AppleFontSmoothing is nudged to medium so thin glyph strokes don't shimmer.
# ============================================================================

WARP_THEMES_SOURCE_DIR="$SCRIPT_DIR/configs/warp/themes"
WARP_SETTINGS_SOURCE="$SCRIPT_DIR/configs/warp/settings.toml"
WARP_WORKFLOWS_SOURCE_DIR="$SCRIPT_DIR/configs/warp/workflows"

# Seed Warp config files. Safe to re-run.
seed_warp_config() {
    local warp_dir="$HOME/.warp"
    local themes_dir="$warp_dir/themes"
    local settings="$warp_dir/settings.toml"

    # --- themes (Cobalt2 + Cobalt2 Dim; settings.toml defaults to Dim) -----
    local src target
    for src in "$WARP_THEMES_SOURCE_DIR"/*.yaml; do
        [[ -e "$src" ]] || continue   # no matches → glob stays literal
        mkdir -p "$themes_dir"
        target="$themes_dir/$(basename "$src")"
        if [[ -f "$target" ]] && cmp -s "$src" "$target"; then
            print_skip "Warp theme $(basename "$src")"
            track_skipped "Warp theme $(basename "$src")"
        else
            cp "$src" "$target"
            print_success "Warp theme seeded: $(basename "$src")"
            track_installed "Warp theme $(basename "$src")"
        fi
    done

    # --- settings.toml (full appearance config), only when absent ----------
    # Warp owns this file and rewrites it as the user changes preferences in
    # the GUI; we only provide a "looks cool" starting point on a fresh install.
    if [[ -f "$settings" ]]; then
        print_skip "Warp settings.toml (exists — left untouched)"
        track_skipped "Warp settings.toml"
        print_info "To apply manually: font 'Cascadia Code NF', theme 'Cobalt2 Dim', vertical tabs + 'aurora' icon in Warp → Settings → Appearance."
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

# Seed repo-owned Warp workflows (parameterized commands in the command palette).
# The repo is the source of truth: copy each when missing or changed; idempotent.
seed_warp_workflows() {
    local workflows_dir="$HOME/.warp/workflows"

    if [[ ! -d "$WARP_WORKFLOWS_SOURCE_DIR" ]]; then
        return 0
    fi

    local src target
    for src in "$WARP_WORKFLOWS_SOURCE_DIR"/*.yaml; do
        [[ -e "$src" ]] || continue   # no matches → glob stays literal
        mkdir -p "$workflows_dir"
        target="$workflows_dir/$(basename "$src")"
        if [[ -f "$target" ]] && cmp -s "$src" "$target"; then
            print_skip "Warp workflow $(basename "$src")"
            track_skipped "Warp workflow $(basename "$src")"
        else
            cp "$src" "$target"
            print_success "Warp workflow seeded: $(basename "$src")"
            track_installed "Warp workflow $(basename "$src")"
        fi
    done
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
    seed_warp_workflows

    # Nudge font smoothing to medium so thin glyph strokes don't shimmer on
    # Retina (pure-crisp rendering strains the eyes). Takes effect on next
    # Warp relaunch; harmless if Warp re-reads it. Idempotent.
    defaults write dev.warp.Warp-Stable AppleFontSmoothing -int 2 2>/dev/null \
        && print_success "Warp font smoothing set to medium" \
        || print_warning "Could not set Warp font smoothing"
}
