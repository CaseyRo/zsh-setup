# shellcheck shell=bash
# ============================================================================
# Splash Screen - Matrix-style intro with figlet header
# ============================================================================

# Function to draw the high-tech progress bar
draw_progress() {
    local width=30
    local filled=$(( ($1 * width) / 100 ))
    local empty=$(( width - filled ))
    printf "\r\033[32m[SYSTEM]: ["
    printf "\033[1;32m"
    [[ $filled -gt 0 ]] && printf "%${filled}s" | tr ' ' '█'
    printf "\033[2m"
    [[ $empty -gt 0 ]] && printf "%${empty}s" | tr ' ' '░'
    printf "\033[0;32m] %d%%" "$1"
}

# Safe clear function that won't hang
safe_clear() {
    # Only clear if we're in a real terminal and it's safe
    if [[ -t 1 ]] && [[ -n "$TERM" ]] && [[ "$TERM" != "dumb" ]]; then
        clear 2>/dev/null || printf "\033[2J\033[H" 2>/dev/null || true
    fi
}

# Safe cmatrix execution with multiple fallback mechanisms
safe_cmatrix() {
    if ! command -v cmatrix &>/dev/null; then
        return 0
    fi

    # Check if we're in a real terminal
    if [[ ! -t 1 ]] || [[ -z "$TERM" ]] || [[ "$TERM" == "dumb" ]]; then
        return 0
    fi

    local timeout_cmd=""
    if command -v timeout &>/dev/null; then
        timeout_cmd="timeout"
    elif command -v gtimeout &>/dev/null; then
        timeout_cmd="gtimeout"
    fi

    if [[ -n "$timeout_cmd" ]]; then
        # Use timeout with signal handling
        # -s KILL ensures it's killed if timeout doesn't work
        if $timeout_cmd -s KILL 2 cmatrix -s -u 10 -C green 2>/dev/null; then
            return 0
        fi
    else
        # Fallback: run cmatrix in background and kill it after timeout
        cmatrix -s -u 10 -C green 2>/dev/null &
        local cmatrix_pid=$!
        sleep 2
        kill "$cmatrix_pid" 2>/dev/null || true
        wait "$cmatrix_pid" 2>/dev/null || true
    fi
}

show_splash() {
    # Enhanced TTY check - skip if not interactive, SKIP env var set, or TERM is dumb
    if [[ ! -t 1 ]] || [[ -n "$SKIP" ]] || [[ -z "$TERM" ]] || [[ "$TERM" == "dumb" ]]; then
        return 0
    fi

    # Wrap entire function in error handling to prevent any failures from blocking installation
    (
        set +e  # Don't exit on errors within this subshell
        
        # Set a trap to ensure we can exit cleanly
        trap 'trap - EXIT INT TERM; exit 0' INT TERM EXIT

        local green='\033[32m'
        local bold_green='\033[1;32m'
        local dim='\033[2m'
        local reset='\033[0m'

        # 1. The Glitch Intro
        safe_clear
        echo -e "${dim}" 2>/dev/null || true
        if command -v figlet &>/dev/null; then
            # Try slant font first, fall back to default if unavailable
            if figlet -f slant "ZSH-setup" 2>/dev/null; then
                sleep 0.1
                safe_clear
                echo -e "${green}" 2>/dev/null || true
                figlet -f slant "ZSH-setup" 2>/dev/null || figlet "ZSH-setup" 2>/dev/null || echo -e "${bold_green}>>> ZSH-SETUP <<<${reset}"
            else
                # slant font not available, use default or fallback
                figlet "ZSH-setup" 2>/dev/null || echo -e "${bold_green}>>> ZSH-SETUP <<<${reset}"
            fi
        else
            echo -e "${bold_green}>>> ZSH-SETUP <<<${reset}"
        fi

        echo -e "${dim}---------------------------------------${reset}"
        echo ""

        # 2. The Binary/Data Decryption Stream
        echo -e "${green}SCANNING KERNEL ARCHITECTURE... $(uname -m)${reset}"
        sleep 0.4
        
        for i in {1..20}; do
            # Generates a flickering line of random characters to look like decryption
            local junk=$(LC_ALL=C head -c 100 /dev/urandom 2>/dev/null | LC_ALL=C tr -dc 'A-Za-z0-9' 2>/dev/null | head -c 45)
            printf "\r${green}DECRYPTING: ${reset}\033[32m%s${reset}" "$junk" 2>/dev/null || true
            sleep 0.04
        done
        echo -e "\r${bold_green}SYSTEM STATUS: ACCESS GRANTED.                      ${reset}"
        sleep 0.3
        echo ""

        # 3. Matrix Rain Burst (if cmatrix exists) - now with better error handling
        safe_cmatrix

        # 4. Smooth Loading Bar
        local i=0
        while [[ $i -le 100 ]]; do
            draw_progress $i 2>/dev/null || true
            sleep 0.03
            i=$((i + 5))
        done
        
        echo -e "\n\n${bold_green}INITIALIZATION COMPLETE.${reset}"
        sleep 0.8
        safe_clear

        # Clear trap
        trap - EXIT INT TERM
    ) || true  # Always return success even if splash screen fails
}
