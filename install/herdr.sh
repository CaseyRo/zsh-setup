#!/bin/bash
# ============================================================================
# herdr config
# ============================================================================
# herdr itself is installed by mise_install_tools (MISE_TOOLS in packages.sh).
# This only seeds the config: Warp-shaped keybindings, the Cobalt2 theme, and
# the sidebar agent-row style.
#
# Copied, not symlinked. herdr rewrites config.toml at runtime (a keybinding
# migration leaves a config.toml.bak-keybind-v2-* behind), and an atomic
# write-then-rename would silently replace a symlink with a regular file —
# the same reason configs/warp/settings.toml is seeded rather than linked.
# ============================================================================

deploy_herdr_config() {
    local config_dir="$HOME/.config/herdr"
    local config_file="$config_dir/config.toml"
    local template="$SCRIPT_DIR/configs/herdr/config.toml"

    if [[ -f "$config_file" ]]; then
        print_skip "herdr config (already exists)"
        track_skipped "herdr config"
        return 0
    fi

    if [[ ! -f "$template" ]]; then
        return 0
    fi

    print_step "Deploying herdr config template"
    mkdir -p "$config_dir"
    cp "$template" "$config_file"
    print_success "herdr config deployed to $config_file"
    track_installed "herdr config"
}
