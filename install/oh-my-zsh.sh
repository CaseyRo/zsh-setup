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
        "olets/zsh-abbr"
        "zsh-users/zsh-syntax-highlighting"
    )

    for plugin in "${plugins[@]}"; do
        local name="${plugin##*/}"
        local dest="$plugin_dir/$name"
        if [[ -d "$dest" ]]; then
            echo "  ✓ $name already installed"
            # Heal existing installs that were cloned before --recurse-submodules
            # was added. zsh-abbr needs olets/zsh-job-queue or `abbr` fails to
            # initialise and silently drops all abbreviations.
            if [[ -f "$dest/.gitmodules" ]]; then
                git -C "$dest" submodule update --init --recursive >/dev/null 2>&1 || true
            fi
        else
            echo "  Installing $name..."
            git clone --depth 1 --recurse-submodules --shallow-submodules \
                "https://github.com/$plugin.git" "$dest"
        fi
    done
}
