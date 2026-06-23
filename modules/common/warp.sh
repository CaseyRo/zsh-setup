# ============================================================================
# Warp terminal tweaks
# ============================================================================
# Warp uses its own input editor and does NOT run zsh's ZLE, so ZLE-driven
# features don't work in it: zsh-autosuggestions, zsh-syntax-highlighting, and
# — relevant here — zsh-abbr abbreviations. That means the Claude Code
# shortcuts defined in modules/common/zz_abbr.sh never expand in Warp.
#
# Fix: define the same shortcuts as real aliases, which resolve at execution
# time regardless of ZLE. Guarded to Warp so normal terminals keep using the
# abbreviations (which expand on SPACE/ENTER and stay visible in history).
#
# Keep this list in sync with modules/common/zz_abbr.sh.
# ============================================================================

if [[ "$TERM_PROGRAM" == "WarpTerminal" ]] && command -v claude >/dev/null 2>&1; then
    alias cl="claude"
    alias clc="claude -c"
    alias clr="claude --resume"

    alias cla="claude --permission-mode auto"
    alias clac="claude --permission-mode auto -c"
    alias clar="claude --permission-mode auto --resume"

    alias clp="claude --permission-mode plan"

    alias cly="claude --dangerously-skip-permissions"
    alias clyc="claude --dangerously-skip-permissions -c"

    alias clmax="claude --effort max"
    alias clweb="claude --chrome"
fi
