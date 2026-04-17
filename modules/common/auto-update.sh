# ============================================================================
# ZSH-Setup: Auto-Update (Periodic Git Sync)
# ============================================================================
# Checks for updates once per day and pulls in the background.
# ============================================================================

ZSH_SETUP_UPDATE_INTERVAL=86400  # 24 hours in seconds
ZSH_SETUP_LAST_UPDATE_FILE="$ZSH_SETUP_FOLDER/.last-update-check"
ZSH_SETUP_LOCK_FILE="$ZSH_SETUP_FOLDER/.update-lock"

cleanup_legacy_zsh_manager() {
    local legacy_dir="$HOME/.zsh-manager"
    local legacy_state="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-manager"
    local legacy_real=""
    local current_real=""

    if [[ -d "$legacy_dir" ]]; then
        legacy_real="$(cd "$legacy_dir" 2>/dev/null && pwd -P)"
    fi
    current_real="$(cd "$ZSH_SETUP_FOLDER" 2>/dev/null && pwd -P)"

    if [[ -n "$legacy_real" ]] && [[ "$legacy_real" != "$current_real" ]]; then
        rm -rf "$legacy_dir"
    fi

    if [[ -d "$legacy_state" ]]; then
        rm -rf "$legacy_state"
    fi
}

# Stash local changes, pull, and pop stash. Returns 0 on success.
_zsh_setup_safe_pull() {
    local stashed=false

    # Stash dirty tree if needed
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        git stash push --quiet -m "zsh-setup auto-update $(date +%Y-%m-%d)" 2>/dev/null && stashed=true
    fi

    if git pull --ff-only --quiet 2>/dev/null; then
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

# Atomic timestamp write (temp file + mv to prevent corruption)
_zsh_setup_write_timestamp() {
    local tmpfile
    tmpfile=$(mktemp "${ZSH_SETUP_LAST_UPDATE_FILE}.XXXXXX" 2>/dev/null) || return 1
    echo "$1" > "$tmpfile" && mv "$tmpfile" "$ZSH_SETUP_LAST_UPDATE_FILE" || rm -f "$tmpfile"
}

# Acquire update lock (prevents concurrent runs from multiple tabs)
_zsh_setup_acquire_lock() {
    if ( set -o noclobber; echo $$ > "$ZSH_SETUP_LOCK_FILE" ) 2>/dev/null; then
        return 0
    fi

    # Check for stale lock (process no longer running)
    local lock_pid
    lock_pid=$(cat "$ZSH_SETUP_LOCK_FILE" 2>/dev/null)
    if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
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
    cleanup_legacy_zsh_manager

    local current_time last_check=0
    current_time=$(date +%s)

    # Read last check time if file exists
    if [[ -f "$ZSH_SETUP_LAST_UPDATE_FILE" ]]; then
        last_check=$(cat "$ZSH_SETUP_LAST_UPDATE_FILE" 2>/dev/null || echo 0)
    fi

    # Check if enough time has passed
    if (( current_time - last_check < ZSH_SETUP_UPDATE_INTERVAL )); then
        return
    fi

    # Acquire lock to prevent concurrent update runs
    _zsh_setup_acquire_lock || return

    # Update timestamp atomically
    _zsh_setup_write_timestamp "$current_time"

    # Pull in background and run upgrade if there were changes
    (
        trap '_zsh_setup_release_lock' EXIT

        cd "$ZSH_SETUP_FOLDER" || exit 1

        # Quick connectivity check (1 second timeout)
        if ! ssh -o ConnectTimeout=2 -o BatchMode=yes -T git@github.com 2>&1 | grep -q "successfully authenticated" 2>/dev/null; then
            # Fallback: try a simple DNS check
            if ! ping -c1 -W1 github.com &>/dev/null; then
                exit 0  # No network, skip silently
            fi
        fi

        git fetch --quiet 2>/dev/null || exit 1

        local behind
        # shellcheck disable=SC1083  # @{upstream} is valid git revision syntax
        behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
        [[ "$behind" -gt 0 ]] || exit 0

        local _old_sha _new_sha _upgrade_log_file
        _upgrade_log_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-setup/upgrades.log"
        _old_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

        if _zsh_setup_safe_pull; then
            _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
            mkdir -p "$(dirname "$_upgrade_log_file")"
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) zsh-setup ${_old_sha:0:7} -> ${_new_sha:0:7} [pulled]" >> "$_upgrade_log_file"
            # Install any new packages added in the update
            if [[ -f "$ZSH_SETUP_FOLDER/install/upgrade.sh" ]]; then
                bash "$ZSH_SETUP_FOLDER/install/upgrade.sh"
            fi
            echo "[zsh-setup] Updated to $(git rev-parse --short HEAD). Restart shell to apply."
        else
            _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
            mkdir -p "$(dirname "$_upgrade_log_file")"
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) zsh-setup ${_old_sha:0:7} -> ${_new_sha:0:7} [pull-failed]" >> "$_upgrade_log_file"
        fi
    ) &>/dev/null &
}

# Run check on shell startup
_zsh_setup_check_update

# Manual update command
zsh-update() {
    cleanup_legacy_zsh_manager

    echo "Updating zsh-setup..."

    cd "$ZSH_SETUP_FOLDER" || { echo "Failed to cd to $ZSH_SETUP_FOLDER"; return 1; }

    git fetch || { echo "Fetch failed. Check your network connection."; return 1; }

    local behind
    # shellcheck disable=SC1083  # @{upstream} is valid git revision syntax
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    if [[ "$behind" -eq 0 ]]; then
        echo "Already up to date."
        return 0
    fi

    echo "$behind commit(s) behind upstream. Pulling..."

    local _old_sha _new_sha _upgrade_log_file
    _upgrade_log_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-setup/upgrades.log"
    _old_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    if ! _zsh_setup_safe_pull; then
        _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        mkdir -p "$(dirname "$_upgrade_log_file")"
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) zsh-setup ${_old_sha:0:7} -> ${_new_sha:0:7} [pull-failed]" >> "$_upgrade_log_file"
        echo "Pull failed. Check 'git status' in $ZSH_SETUP_FOLDER"
        return 1
    fi

    _new_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    mkdir -p "$(dirname "$_upgrade_log_file")"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) zsh-setup ${_old_sha:0:7} -> ${_new_sha:0:7} [pulled]" >> "$_upgrade_log_file"

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
    local log_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-setup/upgrades.log"
    if [[ -f "$log_file" ]]; then
        cat "$log_file"
    else
        echo "No upgrade log found at $log_file"
    fi
}
