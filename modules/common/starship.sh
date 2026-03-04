# ============================================================================
# Starship Prompt Configuration
# ============================================================================

# Only activate if prompt choice is starship
if [[ ! -f "$ZSH_SETUP_FOLDER/.prompt-choice" ]] || [[ "$(cat "$ZSH_SETUP_FOLDER/.prompt-choice" 2>/dev/null)" != "starship" ]]; then
    return 0
fi

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
