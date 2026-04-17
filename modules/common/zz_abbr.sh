# ============================================================================
# Claude Code abbreviations (zsh-abbr)
# ============================================================================
# Why a tail-init (zz_) module: these definitions require the zsh-abbr plugin,
# which is sourced in modules/common/starship.sh. This file must load after
# that. It intentionally sorts before zz_atuin.sh and zz_zoxide.sh — don't
# rename it to something that sorts later.
#
# Naming scheme for the abbreviations:  cl<mode><session>
#   mode:     ''=default  a=auto  p=plan  y=yolo
#   session:  ''=new      c=continue-last  r=resume-picker
# Orthogonal modifiers use full words: clmax (--effort max), clweb (--chrome).
#
# Expansion is triggered by SPACE or ENTER, so the full command is visible in
# the prompt, recorded in history, and picked up by zsh-autosuggestions.

# shellcheck disable=SC1090,SC2215  # abbr is a zsh function from the plugin
if (( ${+functions[abbr]} )); then
    # -S = session-scoped (defined per shell startup, no persistent file)
    # -q = quiet (don't warn on re-definition when the shell reloads)
    abbr -S -q add cl="claude" >/dev/null
    abbr -S -q add clc="claude -c" >/dev/null
    abbr -S -q add clr="claude --resume" >/dev/null

    abbr -S -q add cla="claude --permission-mode auto" >/dev/null
    abbr -S -q add clac="claude --permission-mode auto -c" >/dev/null
    abbr -S -q add clar="claude --permission-mode auto --resume" >/dev/null

    abbr -S -q add clp="claude --permission-mode plan" >/dev/null

    abbr -S -q add cly="claude --dangerously-skip-permissions" >/dev/null
    abbr -S -q add clyc="claude --dangerously-skip-permissions -c" >/dev/null

    abbr -S -q add clmax="claude --effort max" >/dev/null
    abbr -S -q add clweb="claude --chrome" >/dev/null
fi
