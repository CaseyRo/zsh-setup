# ============================================================================
# CLI Styling Utilities
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Symbols
SYMBOL_SUCCESS="✓"
SYMBOL_FAIL="✗"
SYMBOL_ARROW="→"
SYMBOL_BULLET="•"
SYMBOL_SPARKLE="✨"
SYMBOL_PACKAGE="📦"
SYMBOL_WRENCH="🔧"
SYMBOL_ROCKET="🚀"
SYMBOL_CHECK="✅"
SYMBOL_WARN="⚠️"

# Print a styled header
print_header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}  ${BOLD}${WHITE}$1${RESET}"
    echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# Print a section header
print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━ $1 ━━━${RESET}"
    echo ""
}

# Print success message
print_success() {
    echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $1"
}

# Print error message
print_error() {
    echo -e "  ${RED}${SYMBOL_FAIL}${RESET} $1"
}

# Print warning/skip message
print_skip() {
    echo -e "  ${YELLOW}${SYMBOL_ARROW}${RESET} $1 ${DIM}(already installed)${RESET}"
}

# Print info message
print_info() {
    echo -e "  ${BLUE}${SYMBOL_BULLET}${RESET} $1"
}

# Print step being executed
print_step() {
    echo -e "  ${CYAN}${SYMBOL_ARROW}${RESET} $1..."
}

# Print package installation
print_package() {
    echo -e "  ${SYMBOL_PACKAGE} Installing ${BOLD}$1${RESET}..."
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# Platform Detection
# ============================================================================

# Detect if running on ARM architecture (Raspberry Pi, Apple Silicon, etc.)
is_arm() {
    local arch=$(uname -m)
    [[ "$arch" == "arm64" || "$arch" == "aarch64" || "$arch" == "armv"* ]]
}

# Detect if running on Raspberry Pi
is_raspberry_pi() {
    [[ -f /proc/device-tree/model ]] && grep -qi "raspberry" /proc/device-tree/model 2>/dev/null
}

# Detect if running on Debian-based system (Ubuntu, Raspbian, etc.)
is_debian_based() {
    [[ -f /etc/debian_version ]] || command_exists apt-get
}

# Should we use apt instead of brew? (ARM Linux where brew is slow)
should_use_apt() {
    is_arm && is_debian_based && [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Spinner for long-running operations
spinner() {
    local pid=$1
    local message=$2
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r  ${CYAN}${spin:$i:1}${RESET} ${message}..."
        sleep 0.1
    done
    printf "\r"
}

# Run command with spinner
run_with_spinner() {
    local message=$1
    shift

    "$@" &>/dev/null &
    local pid=$!
    spinner $pid "$message"
    wait $pid
    return $?
}

# ============================================================================
# Progress Bar (sticky bottom)
# ============================================================================

PROGRESS_CURRENT=0
PROGRESS_TOTAL=10
PROGRESS_WIDTH=40

# Initialize progress tracking and setup scrolling region
progress_init() {
    PROGRESS_TOTAL=$1
    PROGRESS_CURRENT=0

    # Get terminal height
    local term_height=$(tput lines)

    # Set scrolling region to leave 2 lines at bottom for progress bar
    # CSI r = set scrolling region, CSI H = move cursor home
    printf "\033[1;$((term_height-2))r"

    # Move cursor to top of scrolling region
    printf "\033[1;1H"

    # Draw initial progress bar
    progress_draw "Starting..."
}

# Draw progress bar at bottom (without changing scroll position)
progress_draw() {
    local message=$1

    local percent=$((PROGRESS_CURRENT * 100 / PROGRESS_TOTAL))
    local filled=$((PROGRESS_CURRENT * PROGRESS_WIDTH / PROGRESS_TOTAL))
    local empty=$((PROGRESS_WIDTH - filled))

    # Build the bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    local term_height=$(tput lines)

    # Save cursor position
    printf "\033[s"

    # Move to bottom line (outside scroll region)
    printf "\033[$((term_height-1));1H"

    # Clear line and draw separator
    printf "\033[K"
    echo -e "${DIM}─────────────────────────────────────────────────────────────────${RESET}"

    # Move to last line
    printf "\033[$((term_height));1H"
    printf "\033[K"

    # Print progress bar
    printf "  ${DIM}[${RESET}${GREEN}${bar}${RESET}${DIM}]${RESET} ${BOLD}%3d%%${RESET} ${CYAN}%s${RESET}" "$percent" "$message"

    # Restore cursor position
    printf "\033[u"
}

# Update progress
progress_update() {
    local message=$1
    PROGRESS_CURRENT=$((PROGRESS_CURRENT + 1))
    progress_draw "$message"
}

# Clean up: reset scroll region and clear progress bar area
progress_cleanup() {
    local term_height=$(tput lines)

    # Reset scrolling region to full screen
    printf "\033[r"

    # Move to bottom and clear the progress lines
    printf "\033[$((term_height-1));1H\033[K"
    printf "\033[$((term_height));1H\033[K"

    # Move cursor to a good position
    printf "\033[$((term_height-2));1H"
}

# Legacy function for compatibility
progress_show() {
    progress_draw "Initializing..."
}

# Print final summary
print_summary() {
    # Clean up the sticky progress bar
    progress_cleanup

    # Show completed progress bar inline
    local bar=""
    for ((i=0; i<PROGRESS_WIDTH; i++)); do bar+="█"; done
    echo ""
    echo -e "  ${DIM}[${RESET}${GREEN}${bar}${RESET}${DIM}]${RESET} ${BOLD}100%%${RESET} ${GREEN}All done!${RESET}"

    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${SYMBOL_SPARKLE} ${BOLD}${WHITE}Setup Complete!${RESET} ${SYMBOL_SPARKLE}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${SYMBOL_ROCKET} ${BOLD}Next steps:${RESET}"
    echo -e "     1. Restart your terminal (or run: ${CYAN}source ~/.zshrc${RESET})"
    echo -e "     2. Enjoy your new setup!"
    echo ""
}
