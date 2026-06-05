#!/usr/bin/env bash
# tmux-fzf-url.sh — fuzzy-pick a URL from the current pane and copy it whole.
# ---------------------------------------------------------------------------
# Bound to `prefix + u` in configs/tmux.conf; runs inside tmux `display-popup -E`.
# Self-contained: needs only fzf + tmux (no plugin, no python). Copies via tmux's
# OSC 52 bridge (`set-clipboard on`), so the URL lands on the Mac clipboard across
# the ssh hop — works over cmux's ssh transport (mosh filters OSC 52).
#
# The fix: `capture-pane -J` rejoins tmux's display-wrapped lines first, so a URL
# split across two rows is reconstructed whole before it's matched — exactly the
# "wrapped link pastes broken" problem.
#
# Portable on macOS bash 3.2 (no mapfile/tac) and BSD grep/sed.
#
# Env knobs:
#   TMUX_FZF_URL_LINES   scrollback lines to scan (default 5000)

set -eu

if ! command -v fzf >/dev/null 2>&1; then
    printf 'fzf not found — install it to use the URL picker.\n' >&2
    printf 'press enter to close…' >&2; read -r _ || true
    exit 1
fi

lines="${TMUX_FZF_URL_LINES:-5000}"

# Join wrapped rows, pull URL-ish tokens, trim trailing punctuation, de-dup,
# then reverse so the most recent URLs sit at the top of the picker.
urls=$(
    tmux capture-pane -pJ -S "-${lines}" \
    | grep -oiE '((https?|ftp|file)://|www\.)[A-Za-z0-9._~:/?#@!$&*+,;=%-]+' \
    | sed -E 's/[].,;:!?)]+$//' \
    | awk 'NF && !seen[$0]++ { a[++n]=$0 } END { for (i=n; i>=1; i--) print a[i] }'
)

if [ -z "$urls" ]; then
    printf 'No URLs found in the last %s lines.\n' "$lines" >&2
    printf 'press enter to close…' >&2; read -r _ || true
    exit 0
fi

sel=$(
    printf '%s\n' "$urls" \
    | fzf --no-sort --reverse --multi --height=100% --border=rounded \
          --prompt='url> ' \
          --header='enter: copy   tab: multi-select   esc: cancel'
) || exit 0

[ -n "$sel" ] || exit 0

# -w pushes the buffer to the clipboard via OSC 52.
printf '%s' "$sel" | tmux load-buffer -w -
