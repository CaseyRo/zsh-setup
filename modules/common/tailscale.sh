# ============================================================================
# ZSH-Setup: Tailscale Connection Check
# ============================================================================
# Reminds you to connect Tailscale if it's installed but not running.
# Only shows the reminder once per shell session.
# ============================================================================

_zsh_setup_tailscale_check() {
    # Skip if tailscale CLI isn't available
    # On macOS, the CLI is optional (users can use the menu bar app instead)
    if ! command -v tailscale &>/dev/null; then
        return 0
    fi

    # Check if Tailscale is connected
    # tailscale status exits 0 if logged in, non-zero otherwise
    if ! tailscale status &>/dev/null; then
        echo ""
        echo "\033[0;33m[tailscale]\033[0m Not connected to Tailscale network."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "           Run: \033[0;36mopen -a Tailscale\033[0m or click the menu bar icon"
        else
            echo "           Run: \033[0;36msudo tailscale up\033[0m"
        fi
        echo ""
    fi
}

# Run check on shell startup
_zsh_setup_tailscale_check
