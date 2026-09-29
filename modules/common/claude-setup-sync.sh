# ============================================================================
# ZSH-Setup: casey-claude-setup sync (daily, background)
# ============================================================================
# Once a day, if ~/dev/casey-claude-setup is behind origin, runs its setup.sh in
# the background so fleet Claude Code config (skills, agents, retired-asset
# prunes) reaches this host without a manual run. setup.sh pulls itself; it
# refuses to pull over conflicting local edits, and this module never stashes
# them. Opt out: CLAUDE_SETUP_DISABLE_AUTOSYNC=1.
#
# A sync that fails or degrades says so on every new shell until one succeeds:
# a silent background failure would leave the host drifting unnoticed.
# Log: ${XDG_STATE_HOME:-~/.local/state}/zsh-setup/claude-setup-sync.log
# ============================================================================

CLAUDE_SETUP_DIR="${CLAUDE_SETUP_DIR:-$HOME/dev/casey-claude-setup}"
_CS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-setup"

_claude_setup_sync() {
    [[ -n "${CLAUDE_SETUP_DISABLE_AUTOSYNC:-}" ]] && return
    [[ -x "$CLAUDE_SETUP_DIR/setup.sh" ]] || return
    command -v claude >/dev/null 2>&1 || return

    local stamp="$_CS_STATE/claude-setup-sync.last" result="$_CS_STATE/claude-setup-sync.status"
    local log="$_CS_STATE/claude-setup-sync.log" lock="$_CS_STATE/claude-setup-sync.lock"
    local now last=0 st
    now=$(date +%s)

    if [[ -f "$result" ]]; then
        st=$(cat "$result" 2>/dev/null)
        [[ "$st" == 0 ]] || echo "[claude-setup] last background sync exited $st (2 = degraded, 1 = failed); see $log" >&2
    fi

    [[ -f "$stamp" ]] && last=$(cat "$stamp" 2>/dev/null)
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
    (( now - last < 86400 )) && return

    mkdir -p "$_CS_STATE" 2>/dev/null || return
    # One worker across tabs; a lock older than an hour is from a killed worker.
    if [[ -f "$lock" ]] && (( now - $(cat "$lock" 2>/dev/null || echo 0) > 3600 )); then rm -f "$lock"; fi
    ( set -o noclobber; echo "$now" > "$lock" ) 2>/dev/null || return

    (
        trap 'rm -f "$lock"' EXIT INT TERM HUP
        cd "$CLAUDE_SETUP_DIR" || exit 1
        if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o ConnectTimeout=5 -o BatchMode=yes" \
                git -c credential.helper= fetch --quiet 2>/dev/null; then
            echo "$((now - 86400 + 3600))" > "$stamp"   # offline: retry in an hour, not a day
            exit 0
        fi
        echo "$now" > "$stamp"
        # shellcheck disable=SC1083  # @{upstream} is valid git revision syntax
        [[ "$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)" -eq 0 ]] && exit 0
        echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) $(git rev-parse --short HEAD) -> $(git rev-parse --short '@{upstream}')" >> "$log"
        ./setup.sh >> "$log" 2>&1
        echo "$?" > "$result"
    ) &>/dev/null </dev/null &
}

_claude_setup_sync
