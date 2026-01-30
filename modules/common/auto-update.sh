# ============================================================================
# ZSH-Setup: Auto-Update (Periodic Git Sync)
# ============================================================================
# Checks for updates once per day and pulls in the background.
# ============================================================================

ZSH_SETUP_UPDATE_INTERVAL=86400  # 24 hours in seconds
ZSH_SETUP_LAST_UPDATE_FILE="$ZSH_SETUP_FOLDER/.last-update-check"

cleanup_legacy_zsh_manager() {
    local legacy_dir="${ZSH_MANAGER_DIR:-$HOME/.zsh-manager}"
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

_zsh_setup_check_update() {
    cleanup_legacy_zsh_manager

    local current_time=$(date +%s)
    local last_check=0

    # Read last check time if file exists
    if [[ -f "$ZSH_SETUP_LAST_UPDATE_FILE" ]]; then
        last_check=$(cat "$ZSH_SETUP_LAST_UPDATE_FILE" 2>/dev/null || echo 0)
    fi

    # Check if enough time has passed
    if (( current_time - last_check >= ZSH_SETUP_UPDATE_INTERVAL )); then
        # Update timestamp immediately to prevent multiple checks
        echo "$current_time" > "$ZSH_SETUP_LAST_UPDATE_FILE"

        # Pull in background and run upgrade if there were changes
        (
            cd "$ZSH_SETUP_FOLDER" && \
            git fetch --quiet && \
            local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
            if [[ "$behind" -gt 0 ]]; then
                git pull --quiet && \
                # Install any new packages added in the update
                if [[ -f "$ZSH_SETUP_FOLDER/install/upgrade.sh" ]]; then
                    bash "$ZSH_SETUP_FOLDER/install/upgrade.sh"
                fi
                echo "[zsh-setup] Updated! Restart shell to apply changes."
            fi
            # Clean up Docker if installed
            if command -v docker &>/dev/null; then
                docker system prune -f &>/dev/null
            fi
        ) &>/dev/null &
    fi
}

# Run check on shell startup
_zsh_setup_check_update

# Manual update command
zsh-update() {
    cleanup_legacy_zsh_manager

    echo "Updating zsh-setup..."
    git -C "$ZSH_SETUP_FOLDER" pull
    # Install any new packages added in the update
    if [[ -f "$ZSH_SETUP_FOLDER/install/upgrade.sh" ]]; then
        echo "Checking for new packages..."
        bash "$ZSH_SETUP_FOLDER/install/upgrade.sh"
    fi
    # Clean up Docker if installed
    if command -v docker &>/dev/null; then
        echo "Cleaning up Docker..."
        docker system prune -f
    fi
    echo "Reloading shell config..."
    source ~/.zshrc
    echo "Done!"
}
