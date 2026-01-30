# shellcheck shell=bash
# ============================================================================
# Splash Screen - Matrix-style intro with figlet header
# ============================================================================

show_splash() {
    # Skip if not interactive
    [[ ! -t 1 ]] && return 0

    local green='\033[32m'
    local bold_green='\033[1;32m'
    local dim='\033[2m'
    local reset='\033[0m'

    # Clear screen and set matrix green
    clear
    echo -e "${green}"

    # Display figlet header if available
    if command -v figlet &>/dev/null; then
        figlet -f slant "ZSH-setup" 2>/dev/null || figlet "ZSH-setup"
    else
        echo -e "${bold_green}"
        echo "  _______ _    _       _____      _               "
        echo " |___  / | |  | |     / ____|    | |              "
        echo "    / /  | |__| |    | (___   ___| |_ _   _ _ __  "
        echo "   / /   |  __  |     \\___ \\ / _ \\ __| | | | '_ \\ "
        echo "  / /__  | |  | |     ____) |  __/ |_| |_| | |_) |"
        echo " /_____| |_|  |_|    |_____/ \\___|\\__|\\__,_| .__/ "
        echo "                                           | |    "
        echo "                                           |_|    "
    fi

    echo ""
    echo -e "${dim}---------------------------------------${reset}"
    echo -e "${green}"

    # Theatrical "hacking" sequence
    sleep 0.3
    echo "Establishing secure connection..."
    sleep 0.4
    echo "Loading shell modules..."
    sleep 0.4
    echo "Initializing environment..."
    sleep 0.3
    echo -e "${dim}---------------------------------------${reset}"

    # Matrix rain burst if cmatrix is available
    if command -v cmatrix &>/dev/null; then
        sleep 0.2
        # Run cmatrix for 2 seconds (-s for screensaver mode, -u for speed)
        timeout 2 cmatrix -s -u 8 -C green 2>/dev/null || true
    else
        sleep 0.5
    fi

    # Reset colors and clear for actual installer
    echo -e "${reset}"
    clear
}

# Quick splash without effects (for non-interactive or minimal installs)
show_splash_simple() {
    [[ ! -t 1 ]] && return 0

    local green='\033[1;32m'
    local reset='\033[0m'

    clear
    echo -e "${green}"

    if command -v figlet &>/dev/null; then
        figlet -f slant "ZSH-setup" 2>/dev/null || figlet "ZSH-setup"
    else
        echo "=== ZSH-setup ==="
    fi

    echo -e "${reset}"
    sleep 1
    clear
}
