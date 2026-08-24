# ============================================================================
# Eternal Terminal + herdr — resilient remote agent sessions
# ============================================================================
# `herdr --remote <host>` runs a thin client locally and ships herdr's own
# protocol over SSH: every keystroke is a full round-trip before anything
# renders, and because it is TCP a single lost packet head-of-line-blocks the
# whole UI. On hotel or train wifi that reads as constant lag, and no amount of
# ssh tuning fixes it — the keepalives and ControlMaster socket herdr manages
# only help setup and idle survival.
#
# These helpers invert the arrangement. herdr's session server already IS the
# persistence layer, so the client belongs on the remote box talking to it over
# a unix socket, and the network only has to carry the rendered pty.
#
# ET is the default transport here, not mosh. ET creates a pseudo-terminal on
# the server and pipes the raw byte stream, so herdr's inline images, graphics
# streams and OSC sequences pass through untouched; it reconnects over TCP on
# port 2022, which also survives the many networks that block mosh's UDP
# 60000-61000. mosh emulates the terminal in order to sync screen state and so
# drops whatever it cannot parse — no kitty graphics, and OSC 52 only with the
# `c;` selector (see configs/tmux/tmux-fzf-url.sh, which hit the same wall).
# What mosh still wins is predictive local echo and UDP's freedom from
# head-of-line blocking, so `hhm` keeps it for genuinely lossy or high-RTT
# links, at the cost of those features.
#
# Panes survive either transport dropping, so switching between the two costs
# nothing beyond re-attaching.
# ============================================================================

# Default host for a bare `hh` / `hhm`, e.g. export HERDR_REMOTE_HOST=home
: "${HERDR_REMOTE_HOST:=}"

# Remote path to `etterminal`, passed through as --terminal-path. ET's own
# --macserver flag hardcodes /usr/local/bin/etterminal, which is wrong on this
# fleet: Homebrew lives under ~/homebrew, so etterminal is off the remote
# non-interactive PATH and ET cannot find it. Set this when the remote is a Mac
# with a custom prefix, e.g. ~/homebrew/bin/etterminal
: "${HERDR_REMOTE_ETTERMINAL:=}"

# Session names are embedded in a remote command string; keep them boring.
_herdr_check_session() {
    [[ -z "$1" ]] && return 0
    case "$1" in
        *[!A-Za-z0-9._-]*)
            echo "session name must be [A-Za-z0-9._-], got: $1" >&2
            return 1
            ;;
    esac
    return 0
}

# herdr is mise-installed, so its shim only reaches PATH via the zsh profile.
# Running it through `zsh -lc` is what makes it resolvable over a transport
# that does not start a login shell. `bash -lc` is NOT a substitute — it
# sources bash's startup files and never mise's zsh activation.
_herdr_remote_cmd() {
    if [[ -n "$1" ]]; then
        echo "herdr session attach $1"
    else
        echo "herdr"
    fi
}

_herdr_usage() {
    echo "usage: $1 <host> [session]" >&2
    echo "  e.g. $1 home            → attach the default herdr session" >&2
    echo "       $1 home yorizon    → attach session 'yorizon'" >&2
    echo "  set HERDR_REMOTE_HOST to omit the host argument" >&2
}

# --- hh: ET + herdr (preferred) --------------------------------------------
# Transparent pty pipe, so herdr's images and OSC survive the hop.
hh() {
    local host="${1:-$HERDR_REMOTE_HOST}"
    local session="${2:-}"

    [[ -z "$host" ]] && { _herdr_usage hh; return 1; }
    _herdr_check_session "$session" || return 1

    if ! command -v et >/dev/null 2>&1; then
        echo "hh: et not found — brew install et, or use hhm for the mosh path" >&2
        return 1
    fi

    local -a et_args
    [[ -n "$HERDR_REMOTE_ETTERMINAL" ]] && et_args+=(--terminal-path "$HERDR_REMOTE_ETTERMINAL")

    local remote
    remote="$(_herdr_remote_cmd "$session")"
    et "${et_args[@]}" "$host" -c "zsh -lc '$remote'"
}

# --- hhm: mosh + herdr (lossy-link fallback) -------------------------------
# Predictive echo and no head-of-line blocking; loses inline images and most
# OSC passthrough, because mosh only forwards sequences it understands.
hhm() {
    local host="${1:-$HERDR_REMOTE_HOST}"
    local session="${2:-}"

    [[ -z "$host" ]] && { _herdr_usage hhm; return 1; }
    _herdr_check_session "$session" || return 1

    if ! command -v mosh >/dev/null 2>&1; then
        echo "hhm: mosh not found — brew install mosh, or use hh for the ET path" >&2
        return 1
    fi

    local remote
    remote="$(_herdr_remote_cmd "$session")"
    mosh "$host" -- zsh -lc "$remote"
}
