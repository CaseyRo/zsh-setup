# ============================================================================
# Common Tools & Utilities
# ============================================================================

# fzf (fuzzy finder) — CTRL-T: file picker, CTRL-R: history, ALT-C: cd
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi


# Envman
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Source additional environment file if it exists
[ -s "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
