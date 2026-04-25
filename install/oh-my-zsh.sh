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

    _patch_zsh_autocomplete_stderr_leak "$plugin_dir"
}

# Patch upstream bug in zsh-autocomplete that silently redirects the shell's
# fd 2 to /dev/null on every keystroke pause.
#
# The buggy line in Functions/Init/.autocomplete__async is:
#     exec {_autocomplete__async_fd}<&- 2>/dev/null
# In zsh, `exec` followed by *any* redirect applies that redirect to the
# shell itself, permanently. Intent was per-command error suppression on the
# close; effect is "stderr is dead for the rest of the session." Wrapping the
# close in a brace block scopes the 2>/dev/null to just the close.
#
# Idempotent: matches only the unpatched pattern, exits silently otherwise.
_patch_zsh_autocomplete_stderr_leak() {
    local plugin_dir="$1"
    local target="$plugin_dir/zsh-autocomplete/Functions/Init/.autocomplete__async"
    [[ -f "$target" ]] || return 0

    if ! grep -q '^[[:space:]]*exec {_autocomplete__async_fd}<&- 2>/dev/null$' "$target" 2>/dev/null; then
        return 0
    fi

    cp -n "$target" "$target.bak-stderr-leak" 2>/dev/null || true

    local tmp
    tmp=$(mktemp) || return 1
    if sed -E 's|^([[:space:]]*)exec \{_autocomplete__async_fd\}<&- 2>/dev/null$|\1{ exec {_autocomplete__async_fd}<\&- } 2>/dev/null|' \
            "$target" > "$tmp"; then
        mv "$tmp" "$target"
        echo "  ✓ patched zsh-autocomplete (upstream stderr→/dev/null leak on line ~213)"
    else
        rm -f "$tmp"
        return 1
    fi
}
