# ============================================================================
# Oh My Zsh Configuration
# ============================================================================

# Skip if using Starship prompt
if [[ -f "$ZSH_SETUP_FOLDER/.prompt-choice" ]] && [[ "$(cat "$ZSH_SETUP_FOLDER/.prompt-choice" 2>/dev/null)" == "starship" ]]; then
    return 0
fi

# Oh-My-Zsh path — $HOME works on all platforms
export ZSH="$HOME/.oh-my-zsh"
if [[ "$MACHINE_OS" != "Darwin" ]]; then
    ZSH_DISABLE_COMPFIX=true
fi

# Theme
ZSH_THEME=agnoster

# Plugins
plugins=(zsh-autosuggestions zsh-syntax-highlighting docker docker-compose zsh-autocomplete)

# Auto-update configuration
zstyle ':omz:update' mode auto

# Initialize oh-my-zsh
source $ZSH/oh-my-zsh.sh
