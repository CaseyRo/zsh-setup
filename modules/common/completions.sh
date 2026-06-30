# ============================================================================
# Completion Scripts
# ============================================================================

# Initialize zsh completion engine (skip if zsh-autocomplete already did it)
if ! whence compdef &>/dev/null; then
    autoload -Uz compinit
    compinit
fi

# ----------------------------------------------------------------------------
# carapace — multi-shell completion engine (optional)
# ----------------------------------------------------------------------------
# Adds rich, argument-aware completions for hundreds of CLIs. Bridges to
# existing zsh/bash/fish completers so nothing already working is lost.
# No-op when carapace isn't installed (Homebrew on macOS, prebuilt binary on
# apt systems — see install/prebuilt-bins.sh).
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    # shellcheck disable=SC1090  # dynamic completion script emitted by carapace
    source <(carapace _carapace zsh)
fi
