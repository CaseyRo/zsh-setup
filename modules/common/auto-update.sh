# ============================================================================
# ZSH-Manager: Auto-Update (Periodic Git Sync)
# ============================================================================
# Checks for updates once per day and pulls in the background.
# ============================================================================

ZSH_Manager_UPDATE_INTERVAL=86400  # 24 hours in seconds
ZSH_Manager_LAST_UPDATE_FILE="$ZSH_Manager_FOLDER/.last-update-check"

_zsh_manager_check_update() {
    local current_time=$(date +%s)
    local last_check=0

    # Read last check time if file exists
    if [[ -f "$ZSH_Manager_LAST_UPDATE_FILE" ]]; then
        last_check=$(cat "$ZSH_Manager_LAST_UPDATE_FILE" 2>/dev/null || echo 0)
    fi

    # Check if enough time has passed
    if (( current_time - last_check >= ZSH_Manager_UPDATE_INTERVAL )); then
        # Update timestamp immediately to prevent multiple checks
        echo "$current_time" > "$ZSH_Manager_LAST_UPDATE_FILE"

        # Pull in background and run upgrade if there were changes
        (
            cd "$ZSH_Manager_FOLDER" && \
            git fetch --quiet && \
            local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
            if [[ "$behind" -gt 0 ]]; then
                git pull --quiet && \
                # Install any new packages added in the update
                if [[ -f "$ZSH_Manager_FOLDER/install/upgrade.sh" ]]; then
                    bash "$ZSH_Manager_FOLDER/install/upgrade.sh"
                fi
                echo "[zsh-manager] Updated! Restart shell to apply changes."
            fi
        ) &>/dev/null &
    fi
}

# Run check on shell startup
_zsh_manager_check_update

# Manual update command
zsh-update() {
    echo "Updating zsh-manager..."
    git -C "$ZSH_Manager_FOLDER" pull
    # Install any new packages added in the update
    if [[ -f "$ZSH_Manager_FOLDER/install/upgrade.sh" ]]; then
        echo "Checking for new packages..."
        bash "$ZSH_Manager_FOLDER/install/upgrade.sh"
    fi
    echo "Reloading shell config..."
    source ~/.zshrc
    echo "Done!"
}
