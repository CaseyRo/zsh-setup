#!/bin/bash
# ============================================================================
# Zsh Plugin Installer (standalone, no Oh My Zsh)
# ============================================================================

install_oh_my_zsh() { return 0; }

install_zsh_plugins() {
    local plugin_dir="$HOME/.local/share/zsh-plugins/plugins"
    mkdir -p "$plugin_dir"

    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "marlonrichert/zsh-autocomplete"
        "zsh-users/zsh-syntax-highlighting"
    )

    for plugin in "${plugins[@]}"; do
        local name="${plugin##*/}"
        local dest="$plugin_dir/$name"
        if [[ -d "$dest" ]]; then
            echo "  ✓ $name already installed"
        else
            echo "  Installing $name..."
            git clone --depth 1 "https://github.com/$plugin.git" "$dest"
        fi
    done
}
