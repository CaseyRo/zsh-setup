# shellcheck shell=bash
# ============================================================================
# Zoxide — smarter cd. MUST be the last module loaded (zoxide requirement).
# ----------------------------------------------------------------------------
# --cmd cd: replaces cd with zoxide-aware cd; 'cdi' for interactive fzf picker
# The zz_ prefix + lexicographic sort guarantees this runs after zz_atuin.sh
# and every other module.
# ============================================================================

if command -v zoxide &> /dev/null; then
    export _ZO_DOCTOR=0
    # shellcheck disable=SC1090  # dynamic source from zoxide init
    eval "$(zoxide init zsh --cmd cd)"
fi
