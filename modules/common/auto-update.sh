# ============================================================================
# ZSH-Setup: Auto-Update (Periodic Git Sync)
# ============================================================================
# Checks for updates once per day and pulls in the background.
# Set ZSH_SETUP_DISABLE_AUTOUPDATE=1 to opt out.
# ============================================================================

ZSH_SETUP_UPDATE_INTERVAL=86400  # 24 hours in seconds
ZSH_SETUP_RETRY_INTERVAL=3600    # 1 hour after a network failure
ZSH_SETUP_LAST_UPDATE_FILE="$ZSH_SETUP_FOLDER/.last-update-check"
ZSH_SETUP_LOCK_FILE="$ZSH_SETUP_FOLDER/.update-lock"
ZSH_SETUP_UPGRADE_LOG="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-setup/upgrades.log"

# Append a line to the upgrade audit log. Silent if dir cannot be created.
_zsh_setup_log_event() {
    mkdir -p "$(dirname "$ZSH_SETUP_UPGRADE_LOG")" 2>/dev/null || return 0
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) zsh-setup $*" >> "$ZSH_SETUP_UPGRADE_LOG"
}

# git fetch with short connect/transfer timeouts so we never hang a shell.
# Works for both SSH and HTTPS remotes. GIT_TERMINAL_PROMPT=0 + an empty
# credential helper guarantee we fail fast instead of prompting for creds on
# an HTTPS remote (BatchMode covers the SSH side).
_zsh_setup_fetch() {
    GIT_TERMINAL_PROMPT=0 \
    GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o ConnectTimeout=5 -o BatchMode=yes" \
        git -c credential.helper= -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=10 \
            fetch --quiet 2>/dev/null
}


# Stash local changes, pull, and pop stash. Returns 0 on success.
_zsh_setup_safe_pull() {
    local stashed=false

    # Stash dirty tree if needed
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        git stash push --quiet -m "zsh-setup auto-update $(date +%Y-%m-%d)" 2>/dev/null && stashed=true
    fi

    if GIT_TERMINAL_PROMPT=0 git -c credential.helper= pull --ff-only --quiet 2>/dev/null; then
        if [[ "$stashed" == true ]]; then
            if ! git stash pop --quiet 2>/dev/null; then
                echo "[zsh-setup] Auto-update: stash pop failed. Run 'cd $ZSH_SETUP_FOLDER && git stash pop' to recover." >&2
                return 1
            fi
        fi
        return 0
    else
        # Pull failed (diverged history or merge conflict)
        [[ "$stashed" == true ]] && git stash pop --quiet 2>/dev/null
        echo "[zsh-setup] Auto-update: pull failed (diverged?). Run 'zsh-update' manually." >&2
        return 1
    fi
}

# Lock (_zsh_setup_acquire_lock) serializes writers and the read side tolerates
# a half-written value, so a plain write is enough.
_zsh_setup_write_timestamp() {
    echo "$1" > "$ZSH_SETUP_LAST_UPDATE_FILE"
}

# Acquire update lock (prevents concurrent runs from multiple tabs)
_zsh_setup_acquire_lock() {
    if ( set -o noclobber; echo $$ > "$ZSH_SETUP_LOCK_FILE" ) 2>/dev/null; then
        return 0
    fi

    # Check for stale lock (missing/non-numeric content, or dead PID)
    local lock_pid
    lock_pid=$(cat "$ZSH_SETUP_LOCK_FILE" 2>/dev/null)
    if [[ -z "$lock_pid" ]] || ! [[ "$lock_pid" =~ ^[0-9]+$ ]] || ! kill -0 "$lock_pid" 2>/dev/null; then
        rm -f "$ZSH_SETUP_LOCK_FILE"
        if ( set -o noclobber; echo $$ > "$ZSH_SETUP_LOCK_FILE" ) 2>/dev/null; then
            return 0
        fi
    fi

    return 1  # Another instance is running
}

_zsh_setup_release_lock() {
    rm -f "$ZSH_SETUP_LOCK_FILE"
}

_zsh_setup_check_update() {
    # User opt-out
    [[ -n "${ZSH_SETUP_DISABLE_AUTOUPDATE:-}" ]] && return

    local current_time last_check=0
    current_time=$(date +%s)

    # Read last check time if file exists; fall back to 0 if contents aren't numeric
    if [[ -f "$ZSH_SETUP_LAST_UPDATE_FILE" ]]; then
        last_check=$(cat "$ZSH_SETUP_LAST_UPDATE_FILE" 2>/dev/null || echo 0)
        [[ "$last_check" =~ ^[0-9]+$ ]] || last_check=0
    fi

    # Check if enough time has passed
    if (( current_time - last_check < ZSH_SETUP_UPDATE_INTERVAL )); then
        return
    fi

    # Acquire lock to prevent concurrent update runs
    _zsh_setup_acquire_lock || return

    # Pull in background and run upgrade if there were changes
    (
        trap '_zsh_setup_release_lock' EXIT INT TERM HUP

        cd "$ZSH_SETUP_FOLDER" || exit 1

        if ! _zsh_setup_fetch; then
            # Don't block for a full day — retry on the next shell after RETRY_INTERVAL
            _zsh_setup_write_timestamp \
                "$((current_time - ZSH_SETUP_UPDATE_INTERVAL + ZSH_SETUP_RETRY_INTERVAL))"
            _zsh_setup_log_event "[skipped: fetch-failed]"
            exit 0
        fi

        # Fetch succeeded — lock in the next check for a full interval
        _zsh_setup_write_timestamp "$current_time"

        local behind
        # shellcheck disable=SC1083  # @{upstream} is valid git revision syntax
        behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
        if [[ "$behind" -eq 0 ]]; then
            _zsh_setup_log_event "[up-to-date]"
            exit 0
        fi

        local _old_sha _new_sha
        _old_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

        if _zsh_setup_safe_pull; then
            _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
            _zsh_setup_log_event "${_old_sha:0:7} -> ${_new_sha:0:7} [pulled]"
            # Install any new packages added in the update. UPGRADE_NONINTERACTIVE=1
            # tells upgrade.sh to skip the sudo-requiring steps (apt) — which a
            # background shell can't authorize — while still running the
            # user-space ones (mise/node, cargo, npm, fonts).
            if [[ -f "$ZSH_SETUP_FOLDER/install/upgrade.sh" ]]; then
                UPGRADE_NONINTERACTIVE=1 bash "$ZSH_SETUP_FOLDER/install/upgrade.sh"
            fi
            echo "[zsh-setup] Updated to $(git rev-parse --short HEAD). Restart shell to apply."
        else
            _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
            _zsh_setup_log_event "${_old_sha:0:7} -> ${_new_sha:0:7} [pull-failed]"
        fi
    ) &>/dev/null &
}

# Run check on shell startup
_zsh_setup_check_update

# Manual update command
zsh-update() {
    echo "Updating zsh-setup..."

    cd "$ZSH_SETUP_FOLDER" || { echo "Failed to cd to $ZSH_SETUP_FOLDER"; return 1; }

    if ! _zsh_setup_fetch; then
        _zsh_setup_log_event "[skipped: fetch-failed]"
        echo "Fetch failed. Check your network connection."
        return 1
    fi

    local behind
    # shellcheck disable=SC1083  # @{upstream} is valid git revision syntax
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    if [[ "$behind" -eq 0 ]]; then
        echo "Already up to date."
        _zsh_setup_log_event "[up-to-date]"
        _zsh_setup_write_timestamp "$(date +%s)"
        return 0
    fi

    echo "$behind commit(s) behind upstream. Pulling..."

    local _old_sha _new_sha
    _old_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    if ! _zsh_setup_safe_pull; then
        _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        _zsh_setup_log_event "${_old_sha:0:7} -> ${_new_sha:0:7} [pull-failed]"
        echo "Pull failed. Check 'git status' in $ZSH_SETUP_FOLDER"
        return 1
    fi

    _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    _zsh_setup_log_event "${_old_sha:0:7} -> ${_new_sha:0:7} [pulled]"

    # Install any new packages added in the update
    if [[ -f "$ZSH_SETUP_FOLDER/install/upgrade.sh" ]]; then
        echo "Checking for new packages..."
        bash "$ZSH_SETUP_FOLDER/install/upgrade.sh"
    fi

    # Update timestamp so the background check doesn't re-trigger
    _zsh_setup_write_timestamp "$(date +%s)"

    echo "Done! Open a new shell tab to apply config changes."
}

# View the upgrade audit log
zsh-upgrade-log() {
    if [[ -f "$ZSH_SETUP_UPGRADE_LOG" ]]; then
        cat "$ZSH_SETUP_UPGRADE_LOG"
    else
        echo "No upgrade log found at $ZSH_SETUP_UPGRADE_LOG"
    fi
}
