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

# ============================================================================
# Herdr desktop (herdr-app) cockpit
# ============================================================================
# The cockpit layout, its two mods, the moss day / Cobalt evening themes and
# keys.json, copied into ~/.config/herdr-app when missing or changed: the repo
# is the source of truth, as for the Warp themes. Copied, not symlinked, for
# the same write-then-rename reason as above. Herdr writes the rest of that
# folder itself. keychron-q11's bin/herdr-daylight switches the two themes.
# PRODUCT.md is the brief behind it and stays in the repo.
# ============================================================================

deploy_herdr_app_config() {
    local app_dir="$HOME/.config/herdr-app"
    local source_dir="$SCRIPT_DIR/configs/herdr-app"
    [[ -d "$source_dir" ]] || return 0

    # Herdr makes the folder on its first start; before that there is nothing to theme.
    if [[ ! -d "$app_dir" ]]; then
        print_skip "Herdr desktop config (open Herdr once, then re-run)"
        track_skipped "Herdr desktop config"
        return 0
    fi

    local src rel target
    while IFS= read -r -d '' src; do
        rel="${src#"$source_dir"/}"
        [[ "$rel" == PRODUCT.md ]] && continue
        target="$app_dir/$rel"
        if [[ -f "$target" ]] && cmp -s "$src" "$target"; then
            continue
        fi
        mkdir -p "$(dirname "$target")"
        cp "$src" "$target"
        print_success "Herdr desktop: $rel"
        track_installed "Herdr desktop $rel"
    done < <(find "$source_dir" -type f -print0)
}
