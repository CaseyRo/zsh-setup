# ============================================================================
# Common Tools & Utilities
# ============================================================================

# fzf (fuzzy finder) — CTRL-T: file picker, CTRL-R: history, ALT-C: cd
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

# Zoxide (smart directory jumper)
# --cmd cd: replaces cd with zoxide-aware version that uses builtin cd for
# exact paths and zoxide ranking for fuzzy matches. Also creates 'cdi' for
# interactive selection via fzf.
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# Envman
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Source additional environment file if it exists
[ -s "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
