# ============================================================================
# Oh My Zsh Configuration
# ============================================================================

# Oh-My-Zsh path — $HOME works on all platforms
export ZSH="$HOME/.oh-my-zsh"
if [[ "$MACHINE_OS" != "Darwin" ]]; then
    ZSH_DISABLE_COMPFIX=true
fi

# Theme
ZSH_THEME=agnoster

# Plugins
plugins=(zsh-autosuggestions docker docker-compose zsh-autocomplete)

# Auto-update configuration
zstyle ':omz:update' mode auto

# Initialize oh-my-zsh
source $ZSH/oh-my-zsh.sh
