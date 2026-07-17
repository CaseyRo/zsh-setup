# ============================================================================
# Completion Scripts
# ============================================================================
# Why zz_ (tail-init): this MUST load after the plugins sourced in
# modules/common/starship.sh. zsh-autocomplete defers compinit to the first
# prompt and owns the dump file. If we run compinit before it loads, then at
# the first prompt autocomplete sees a foreign compinit already ran, deletes
# ~/.zcompdump, and rebuilds it from scratch — so compinit runs twice and the
# dump cache is never reused. That cost ~700ms on every shell.
#
# As a plain "completions.sh" this file sorted 3rd, before starship.sh (9th),
# so the guard below could never see zsh-autocomplete's compdef and always
# ran compinit. Loading here makes the guard meaningful:
#   - autocomplete present -> compdef exists -> we skip; it owns compinit.
#   - autocomplete absent  -> we own compinit, so carapace still gets compdef.
# Don't rename this to sort before starship.sh. It stays before zz_zoxide.sh.

# Deliberately no `compinit -C` here. It would shave ~20ms more by trusting the
# dump and skipping the fpath scan, but then a newly installed tool's
# completions would never appear until the dump was deleted by hand — a silent
# failure that's hard to trace back to here. Not worth 20ms of a ~700ms win.
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
