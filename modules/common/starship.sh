# ============================================================================
# Starship Prompt Configuration
# ============================================================================

# Only activate if prompt choice is starship
if [[ ! -f "$ZSH_SETUP_FOLDER/.prompt-choice" ]] || [[ "$(cat "$ZSH_SETUP_FOLDER/.prompt-choice" 2>/dev/null)" != "starship" ]]; then
    return 0
fi

# --------------------------------------------------------------------------
# Hostname → deterministic color (golden-ratio hash scatter)
# Picks a vibrant bg color unique per hostname, so every server looks different.
# On SSH: patches a copy of starship.toml with the computed color.
# Locally: uses the config as-is (hostname badge is hidden via ssh_only).
# --------------------------------------------------------------------------
_starship_base_config="${ZSH_SETUP_FOLDER}/configs/starship.toml"

if [[ (-n "$SSH_CONNECTION" || -n "$SSH_TTY") ]]; then
    _host_colors=(
        "#f7768e"   # red
        "#ff9e64"   # orange
        "#e0af68"   # yellow
        "#9ece6a"   # green
        "#73daca"   # teal
        "#7dcfff"   # sky
        "#7aa2f7"   # blue
        "#bb9af7"   # purple
        "#ff007c"   # hot pink
        "#c53b53"   # crimson
        "#449dab"   # dark cyan
        "#0db9d7"   # bright cyan
        "#b4f9f8"   # mint
        "#ffc777"   # gold
        "#c3e88d"   # lime
        "#82aaff"   # periwinkle
    )
    # Hash: sum of char values × golden ratio, mod palette size
    _hash=0
    _hn="$(hostname -s)"
    for (( i=0; i<${#_hn}; i++ )); do
        _hash=$(( (_hash + $(printf '%d' "'${_hn:$i:1}")) * 2654435761 ))
    done
    _idx=$(( (_hash & 0x7FFFFFFF) % ${#_host_colors[@]} ))
    _color="${_host_colors[$((_idx + 1))]}"

    # Build a patched config with the computed color
    _patched="/tmp/starship-${_hn}.toml"
    if [[ ! -f "$_patched" ]] || [[ "$_starship_base_config" -nt "$_patched" ]]; then
        sed "s|__HOST_COLOR__|${_color}|g" "$_starship_base_config" > "$_patched"
    fi
    export STARSHIP_CONFIG="$_patched"

    unset _hash _hn _idx _host_colors _color _patched
fi

unset _starship_base_config

# Initialize Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Source plugins directly (no Oh-My-Zsh framework)
local _plugin_dir="$HOME/.local/share/zsh-plugins/plugins"

if [[ -f "$_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -f "$_plugin_dir/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
    source "$_plugin_dir/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
fi

# syntax-highlighting must be sourced last
if [[ -f "$_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
