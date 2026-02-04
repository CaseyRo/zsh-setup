# ============================================================================
# macOS PATH Configuration
# ============================================================================

if [[ -d "$HOME/homebrew/bin" ]]; then
    export PATH="$HOME/homebrew/bin:$PATH"
fi

export PATH=$HOME/ruby-2.7.2/bin:/usr/local/go/bin:$PATH
