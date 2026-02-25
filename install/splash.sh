# shellcheck shell=bash
# ============================================================================
# Splash — quick header for the installer
# ============================================================================

show_splash() {
    [[ ! -t 1 ]] || [[ "$TERM" == "dumb" ]] && return 0

    local dim=$'\033[2m'
    local bold=$'\033[1m'
    local reset=$'\033[0m'

    echo ""

    # Rainbow figlet: toilet -F gay > figlet > plain text
    if command -v toilet &>/dev/null; then
        toilet -f slant -F gay "zsh-setup" 2>/dev/null || toilet -F gay "zsh-setup" 2>/dev/null || echo "${bold}zsh-setup${reset}"
    elif command -v figlet &>/dev/null; then
        figlet -f slant "zsh-setup" 2>/dev/null || figlet "zsh-setup" 2>/dev/null || echo "${bold}zsh-setup${reset}"
    else
        echo "${bold}zsh-setup${reset}"
    fi

    # One-liner with real info
    local arch
    arch="$(uname -m)"
    local platform="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        platform="macOS"
    elif [[ -f /sys/firmware/devicetree/base/model ]] && grep -qi raspberry /sys/firmware/devicetree/base/model 2>/dev/null; then
        platform="Raspberry Pi"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        platform="Linux"
    fi

    echo "${dim}${platform} ${arch} · $(date '+%Y-%m-%d %H:%M')${reset}"
    echo ""
}
