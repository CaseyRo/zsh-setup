#!/bin/bash

# ============================================================================
# ZSH-Setup - The Ultimate Matrix Boot Sequence
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

show_splash() {
    # Skip if not interactive or if SKIP env var is set
    [[ ! -t 1 || -n "$SKIP" ]] && return 0

    local green='\033[32m'
    local bold_green='\033[1;32m'
    local dim='\033[2m'
    local reset='\033[0m'

    # 1. The Glitch Intro
    clear
    echo -e "${dim}"
    if command -v figlet &>/dev/null; then
        figlet -f slant "ZSH-setup"
        sleep 0.1
        clear
        echo -e "${green}"
        figlet -f slant "ZSH-setup"
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
        local junk=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 45)
        printf "\r${green}DECRYPTING: ${reset}\033[32m%s${reset}" "$junk"
        sleep 0.04
    done
    echo -e "\r${bold_green}SYSTEM STATUS: ACCESS GRANTED.                      ${reset}"
    sleep 0.3
    echo ""

    # 3. Matrix Rain Burst (if cmatrix exists)
    if command -v cmatrix &>/dev/null; then
        # -s: Screensaver mode, -u: delay (speed), -C: Color
        timeout 2 cmatrix -s -u 10 -C green 2>/dev/null || true
    fi

    # 4. Smooth Loading Bar
    for i in {0..100..5}; do
        draw_progress $i
        sleep 0.03
    done
    
    echo -e "\n\n${bold_green}INITIALIZATION COMPLETE.${reset}"
    sleep 0.8
    clear
}

# --- SCRIPT EXECUTION STARTS HERE ---

show_splash

# Actual Logic Follows
echo "--- ZSH SETUP UTILITY ---"
echo "Now proceeding with the actual installation..."

# Example: Check for ZSH installation
if command -v zsh &>/dev/null; then
    echo "Check: ZSH is already installed."
else
    echo "Action: Installing ZSH..."
fi

# End of script
