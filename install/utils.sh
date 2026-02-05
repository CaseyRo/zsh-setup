# shellcheck shell=bash
# ============================================================================
# CLI Styling Utilities
# ============================================================================

# Installation tracking
declare -a INSTALLED_ITEMS=()
declare -a SKIPPED_ITEMS=()
declare -a FAILED_ITEMS=()
LOG_FILE=""

# Base colors (themeable)
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_MAGENTA=$'\033[0;35m'
COLOR_CYAN=$'\033[0;36m'
COLOR_WHITE=$'\033[0;37m'
COLOR_BOLD=$'\033[1m'
COLOR_DIM=$'\033[2m'
COLOR_RESET=$'\033[0m'

# Active theme colors (set in ui_init)
RED="$COLOR_RED"
GREEN="$COLOR_GREEN"
YELLOW="$COLOR_YELLOW"
BLUE="$COLOR_BLUE"
MAGENTA="$COLOR_MAGENTA"
CYAN="$COLOR_CYAN"
WHITE="$COLOR_WHITE"
BOLD="$COLOR_BOLD"
DIM="$COLOR_DIM"
RESET="$COLOR_RESET"

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

# ============================================================================
# UI Layout / Theme
# ============================================================================

UI_MODE="${ZSH_SETUP_UI:-${ZSH_MANAGER_UI:-auto}}"
UI_THEME="${ZSH_SETUP_THEME:-${ZSH_MANAGER_THEME:-classic}}"
UI_TTY=false
UI_HAS_TUI=false
UI_GUM=false
UI_NO_COLOR=false
UI_WARN_GUM_MISSING=false
UI_START_TIME=0
UI_WIDTH=80
UI_HEIGHT=24
UI_HEADER_LINES=2
UI_FOOTER_LINES=3
UI_PLATFORM="Unknown"
UI_LAST_ERROR=""
UI_STATUS_NOW="Starting..."

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
    ui_set_error "$1"
}

# Print warning/skip message
print_skip() {
    echo -e "  ${YELLOW}${SYMBOL_ARROW}${RESET} $1 ${DIM}(already installed)${RESET}"
}

# ============================================================================
# Logging
# ============================================================================

log_line() {
    if [[ -n "$LOG_FILE" ]]; then
        printf "%s\n" "$1" >> "$LOG_FILE"
    fi
}

log_kv() {
    log_line "$1: $2"
}

log_init() {
    local base_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-setup"
    local ts

    mkdir -p "$base_dir"
    # Keep only the most recent logs to avoid unbounded growth.
    local keep_logs=5
    local old_logs=()
    local old_count
    local remove_count

    # Avoid mapfile for macOS bash 3.2 compatibility.
    while IFS= read -r line; do
        old_logs+=("$line")
    done < <(ls -1t "$base_dir"/install-*.log 2>/dev/null)
    old_count=${#old_logs[@]}
    if (( old_count > keep_logs )); then
        remove_count=$((old_count - keep_logs))
        for ((i=old_count-1; i>=keep_logs; i--)); do
            rm -f -- "${old_logs[$i]}"
        done
        log_line "Log retention: removed $remove_count old log(s)"
    fi

    ts=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$base_dir/install-$ts.log"

    printf "ZSH-Setup install log\n" > "$LOG_FILE"
    printf "Started: %s\n\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG_FILE"
}

# Track an installed item (for summary)
track_installed() {
    INSTALLED_ITEMS+=("$1")
    log_line "INSTALLED: $1"
}

# Track a skipped item (for summary)
track_skipped() {
    SKIPPED_ITEMS+=("$1")
    log_line "SKIPPED: $1"
}

# Track a failed item (for summary)
track_failed() {
    FAILED_ITEMS+=("$1")
    ui_set_error "$1"
    log_line "FAILED: $1"
}

# Print info message
print_info() {
    echo -e "  ${BLUE}${SYMBOL_BULLET}${RESET} $1"
}

# Print warning message
print_warning() {
    echo -e "  ${YELLOW}${SYMBOL_WARN}${RESET} $1"
}

# Print step being executed
print_step() {
    echo -e "  ${CYAN}${SYMBOL_ARROW}${RESET} $1..."
    ui_set_now "$1"
}

# Print package installation
print_package() {
    echo -e "  ${SYMBOL_PACKAGE} Installing ${BOLD}$1${RESET}..."
}

# Confirm prompt (gum-aware)
ui_confirm() {
    local prompt="$1"

    # Auto-confirm if -y flag was passed
    if [[ "${YES_TO_ALL:-false}" == true ]]; then
        echo -e "  $prompt ${DIM}(auto-confirmed)${RESET}"
        return 0
    fi

    if [[ "$UI_GUM" == true ]]; then
        gum confirm "$prompt"
        return $?
    fi

    read -p "  $prompt [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        return 1
    fi
    return 0
}

# Clear screen safely
ui_clear() {
    # Screen clearing disabled - no-op
    return 0
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# Battery Detection (for installer safety checks)
# ============================================================================

has_battery() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command_exists pmset && pmset -g batt 2>/dev/null | grep -q "Battery Power"
        return $?
    fi

    if [[ -d /sys/class/power_supply ]]; then
        ls /sys/class/power_supply/BAT* &>/dev/null
        return $?
    fi

    return 1
}

get_battery_percent() {
    local percent=""

    if [[ "$OSTYPE" == "darwin"* ]] && command_exists pmset; then
        percent=$(pmset -g batt 2>/dev/null | awk -F';' 'NR==2 {gsub(/[^0-9]/,"",$1); print $1}')
    elif [[ -d /sys/class/power_supply ]]; then
        local capacity_file
        capacity_file=$(ls /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
        if [[ -n "$capacity_file" ]]; then
            percent=$(cat "$capacity_file" 2>/dev/null)
        fi
    fi

    if [[ -n "$percent" ]] && [[ "$percent" =~ ^[0-9]+$ ]]; then
        echo "$percent"
        return 0
    fi

    return 1
}

# Detect if terminal supports TTY output
ui_is_tty() {
    [[ -t 1 && -t 0 && "${TERM:-}" != "dumb" ]]
}

# Disable color output
ui_disable_colors() {
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    BOLD=""
    DIM=""
    RESET=""
}

# Apply theme colors
ui_apply_theme() {
    case "$UI_THEME" in
        classic)
            RED="$COLOR_RED"
            GREEN="$COLOR_GREEN"
            YELLOW="$COLOR_YELLOW"
            BLUE="$COLOR_BLUE"
            MAGENTA="$COLOR_MAGENTA"
            CYAN="$COLOR_CYAN"
            WHITE="$COLOR_WHITE"
            BOLD="$COLOR_BOLD"
            DIM="$COLOR_DIM"
            RESET="$COLOR_RESET"
            ;;
        mono)
            ui_disable_colors
            ;;
        minimal)
            RED="$COLOR_RED"
            GREEN="$COLOR_GREEN"
            YELLOW="$COLOR_YELLOW"
            BLUE=""
            MAGENTA=""
            CYAN=""
            WHITE=""
            BOLD="$COLOR_BOLD"
            DIM="$COLOR_DIM"
            RESET="$COLOR_RESET"
            ;;
        *)
            UI_THEME="classic"
            ui_apply_theme
            ;;
    esac
}

# Initialize UI settings
ui_init() {
    local requested_mode="${1:-$UI_MODE}"
    local requested_theme="${2:-$UI_THEME}"

    UI_MODE="$requested_mode"
    UI_THEME="$requested_theme"
    UI_NO_COLOR=false
    UI_WARN_GUM_MISSING=false
    UI_TTY=false
    UI_GUM=false
    UI_HAS_TUI=false

    if [[ -n "${NO_COLOR:-}" ]]; then
        UI_NO_COLOR=true
    fi

    if ui_is_tty; then
        UI_TTY=true
    fi

    case "$UI_MODE" in
        ""|auto)
            if [[ "$UI_TTY" == true ]]; then
                UI_MODE="classic"
            else
                UI_MODE="plain"
            fi
            ;;
        plain|classic|gum)
            ;;
        *)
            UI_MODE="classic"
            ;;
    esac

    if [[ "$UI_MODE" == "plain" || "$UI_TTY" == false ]]; then
        UI_HAS_TUI=false
        UI_NO_COLOR=true
    else
        UI_HAS_TUI=true
    fi

    if [[ "$UI_MODE" == "gum" ]]; then
        if [[ "$UI_TTY" == true && "$UI_NO_COLOR" == false ]] && command_exists gum; then
            UI_GUM=true
        else
            UI_GUM=false
            UI_WARN_GUM_MISSING=true
            UI_MODE="classic"
            UI_HAS_TUI=true
        fi
    fi

    if [[ "$UI_NO_COLOR" == true ]]; then
        ui_disable_colors
    else
        ui_apply_theme
    fi

    UI_START_TIME=$SECONDS
}

ui_set_context() {
    UI_PLATFORM="$1"
}

ui_set_now() {
    UI_STATUS_NOW="$1"
}

ui_set_error() {
    UI_LAST_ERROR="$1"
    if [[ "$UI_HAS_TUI" == true ]]; then
        progress_draw "$UI_STATUS_NOW"
    fi
}

ui_refresh_dimensions() {
    if [[ "$UI_HAS_TUI" == true ]]; then
        UI_WIDTH=$(tput cols 2>/dev/null || echo 80)
        UI_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    else
        UI_WIDTH=80
        UI_HEIGHT=24
    fi
}

ui_format_elapsed() {
    local elapsed=$((SECONDS - UI_START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    printf "%02d:%02d" "$minutes" "$seconds"
}

ui_pad_line() {
    local left="$1"
    local right="$2"
    local width="$UI_WIDTH"
    local pad=$((width - ${#left} - ${#right}))

    if (( pad < 1 )); then
        local max_left=$((width - ${#right} - 1))
        if (( max_left < 0 )); then
            max_left=0
        fi
        left="${left:0:max_left}"
        pad=$((width - ${#left} - ${#right}))
        if (( pad < 1 )); then
            right="${right:0:$((width - ${#left} - 1))}"
            pad=$((width - ${#left} - ${#right}))
        fi
    fi

    printf "%s%*s%s" "$left" "$pad" "" "$right"
}

ui_gum_style() {
    local text="$1"
    shift
    if [[ "$UI_GUM" == true ]]; then
        gum style "$@" <<<"$text" 2>/dev/null | tr -d '\n'
    else
        printf "%s" "$text"
    fi
}

ui_render_line() {
    local text="$1"
    local style="$2"

    if [[ "$UI_GUM" == true ]]; then
        case "$style" in
            header1)
                ui_gum_style "$text" --bold
                ;;
            header2)
                ui_gum_style "$text"
                ;;
            status)
                ui_gum_style "$text"
                ;;
            separator)
                ui_gum_style "$text"
                ;;
            progress)
                ui_gum_style "$text"
                ;;
            *)
                ui_gum_style "$text"
                ;;
        esac
        return 0
    fi

    case "$style" in
        header1)
            printf "%s%s%s" "${BOLD}${MAGENTA}" "$text" "${RESET}"
            ;;
        header2)
            printf "%s%s%s" "${DIM}" "$text" "${RESET}"
            ;;
        status)
            printf "%s%s%s" "${CYAN}" "$text" "${RESET}"
            ;;
        separator)
            printf "%s%s%s" "${DIM}" "$text" "${RESET}"
            ;;
        progress)
            printf "%s" "$text"
            ;;
        *)
            printf "%s" "$text"
            ;;
    esac
}

ui_draw_header() {
    [[ "$UI_HAS_TUI" == true ]] || return 0

    ui_refresh_dimensions

    local left1="ZSH-Setup Installer"
    local right1=""
    local elapsed
    elapsed=$(ui_format_elapsed)
    local left2="Platform: ${UI_PLATFORM}"
    local right2="Steps: ${PROGRESS_CURRENT}/${PROGRESS_TOTAL}  Elapsed: ${elapsed}"

    local line1
    local line2
    line1=$(ui_pad_line "$left1" "$right1")
    line2=$(ui_pad_line "$left2" "$right2")

    printf "\033[s"
    printf "\033[1;1H"
    printf "\033[K"
    ui_render_line "$line1" "header1"
    printf "\033[2;1H"
    printf "\033[K"
    ui_render_line "$line2" "header2"
    printf "\033[u"
}

ui_draw_footer() {
    local message="$1"

    [[ "$UI_HAS_TUI" == true ]] || return 0
    ui_refresh_dimensions

    if [[ -n "$message" ]]; then
        UI_STATUS_NOW="$message"
    fi

    local term_height=$UI_HEIGHT
    local sep_line
    sep_line=$(printf "%*s" "$UI_WIDTH" "" | tr ' ' '─')

    local status_left="Now: ${UI_STATUS_NOW}"
    local status_right=""
    if [[ -n "$UI_LAST_ERROR" ]]; then
        status_right="Last error: ${UI_LAST_ERROR}"
    fi
    local status_line
    status_line=$(ui_pad_line "$status_left" "$status_right")

    local percent=0
    if (( PROGRESS_TOTAL > 0 )); then
        percent=$((PROGRESS_CURRENT * 100 / PROGRESS_TOTAL))
    fi
    local bar_width=$((UI_WIDTH - 20))
    if (( bar_width < 10 )); then
        bar_width=10
    elif (( bar_width > 60 )); then
        bar_width=60
    fi
    local filled=0
    if (( PROGRESS_TOTAL > 0 )); then
        filled=$((PROGRESS_CURRENT * bar_width / PROGRESS_TOTAL))
    fi
    local empty=$((bar_width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    local progress_line
    progress_line=$(ui_pad_line "Progress [${bar}] ${percent}%" "")

    printf "\033[s"
    printf "\033[$((term_height-2));1H"
    printf "\033[K"
    ui_render_line "$sep_line" "separator"
    printf "\033[$((term_height-1));1H"
    printf "\033[K"
    ui_render_line "$status_line" "status"
    printf "\033[$((term_height));1H"
    printf "\033[K"
    ui_render_line "$progress_line" "progress"
    printf "\033[u"
}

# Run command, respecting VERBOSE flag
# Usage: run_cmd <command> [args...]
run_cmd() {
    if [[ "$VERBOSE" == true ]]; then
        "$@"
    else
        "$@" &>/dev/null
    fi
}

# Redirect for commands - returns the redirect string
# Usage: some_command $(quiet_redirect)
quiet_redirect() {
    if [[ "$VERBOSE" == true ]]; then
        echo ""
    else
        echo "&>/dev/null"
    fi
}

# ============================================================================
# Shell Configuration
# ============================================================================

# Set zsh as the default shell
set_default_shell_zsh() {
    print_section "Default Shell"

    # Check if zsh is installed
    if ! command_exists zsh; then
        print_error "zsh is not installed - cannot set as default shell"
        track_failed "default shell"
        return 1
    fi

    local zsh_path
    zsh_path=$(which zsh)

    # Get current shell
    local current_shell
    current_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")

    # Check if zsh is already the default
    if [[ "$current_shell" == *"zsh"* ]]; then
        print_skip "zsh is already default shell"
        track_skipped "default shell"
        return 0
    fi

    print_step "Setting zsh as default shell"

    # Ensure zsh is in /etc/shells (required for chsh)
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        print_step "Adding zsh to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change the default shell
    if sudo chsh -s "$zsh_path" "$USER"; then
        print_success "Default shell changed to zsh"
        print_info "Log out and back in for the change to take effect"
        track_installed "default shell (zsh)"
        # Set flag to indicate shell was changed
        export SHELL_CHANGED=true
    else
        print_error "Failed to change default shell"
        print_info "You can manually run: chsh -s $(which zsh)"
        track_failed "default shell"
        return 1
    fi
}

# ============================================================================
# Ownership/Permission Checks
# ============================================================================

# Check if a directory is owned by root and print fix instructions
# Usage: check_dir_ownership <dir> <name>
# Returns: 0 if OK, 1 if owned by root
check_dir_ownership() {
    local dir="$1"
    local name="$2"

    [[ -d "$dir" ]] || return 0

    local owner
    # Linux uses -c '%U', macOS uses -f '%Su'
    owner=$(stat -c '%U' "$dir" 2>/dev/null || stat -f '%Su' "$dir" 2>/dev/null)

    if [[ "$owner" == "root" ]]; then
        print_error "$name directory is owned by root"
        print_info "Fix with: sudo chown -R \$USER:\$USER $dir"
        return 1
    fi
    return 0
}

# Check if a file is executable and try to fix it
# Usage: check_binary_executable <path> <name>
# Returns: 0 if OK or fixed, 1 if cannot fix
check_binary_executable() {
    local path="$1"
    local name="$2"

    [[ -f "$path" ]] || return 0

    if [[ -x "$path" ]]; then
        return 0
    fi

    print_step "Fixing $name permissions"
    if chmod +x "$path" 2>/dev/null; then
        return 0
    fi

    local owner
    owner=$(stat -c '%U' "$path" 2>/dev/null || stat -f '%Su' "$path" 2>/dev/null)
    if [[ "$owner" == "root" ]]; then
        print_error "$name is owned by root. Fix with: sudo chown \$USER:\$USER $path"
    else
        print_error "Cannot fix $name permissions"
    fi
    return 1
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

# Detect if running on Ubuntu
is_ubuntu() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* ]]
    else
        return 1
    fi
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

    if [[ "$UI_HAS_TUI" != true ]]; then
        wait $pid
        return $?
    fi

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r  ${CYAN}${spin:$i:1}${RESET} ${message}..."
        sleep 0.1
    done
    printf "\r"
}

# Run command with spinner (or verbose output)
run_with_spinner() {
    local message=$1
    shift

    if [[ "$VERBOSE" == true ]]; then
        echo -e "  ${CYAN}${SYMBOL_ARROW}${RESET} $message..."
        "$@"
        return $?
    elif [[ "$UI_HAS_TUI" != true ]]; then
        "$@" &>/dev/null
        return $?
    else
        "$@" &>/dev/null &
        local pid=$!
        spinner $pid "$message"
        wait $pid
        return $?
    fi
}

# ============================================================================
# Progress Bar (sticky bottom)
# ============================================================================

PROGRESS_CURRENT=0
PROGRESS_TOTAL=10
PROGRESS_WIDTH=40

# Initialize progress tracking and setup scrolling region
progress_init() {
    # Progress bar disabled - no-op
    return 0
}

# Draw progress bar at bottom (without changing scroll position)
progress_draw() {
    # Progress bar disabled - no-op
    return 0
}

# Update progress
progress_update() {
    # Progress bar disabled - no-op
    return 0
}

# Clean up: reset scroll region and preserve output
progress_cleanup() {
    # Progress bar disabled - no-op
    return 0
}

# Legacy function for compatibility
progress_show() {
    progress_draw "Initializing..."
}

# Print final summary
print_summary() {
    local elapsed
    elapsed=$(ui_format_elapsed)
    local installed_count=${#INSTALLED_ITEMS[@]}
    local skipped_count=${#SKIPPED_ITEMS[@]}
    local failed_count=${#FAILED_ITEMS[@]}

    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${SYMBOL_SPARKLE} ${BOLD}${WHITE}Setup Complete!${RESET} ${SYMBOL_SPARKLE}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"

    echo ""
    echo -e "  ${DIM}Summary:${RESET} Installed ${installed_count}, Skipped ${skipped_count}, Failed ${failed_count}, Elapsed ${elapsed}"
    log_line ""
    log_line "Summary: Installed ${installed_count}, Skipped ${skipped_count}, Failed ${failed_count}, Elapsed ${elapsed}"

    # Show what was installed
    if [[ $installed_count -gt 0 ]]; then
        echo ""
        echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} ${BOLD}Installed (${installed_count}):${RESET}"
        for item in "${INSTALLED_ITEMS[@]}"; do
            echo -e "     ${DIM}•${RESET} $item"
        done
    fi

    # Show what was skipped
    if [[ $skipped_count -gt 0 ]]; then
        echo ""
        echo -e "  ${YELLOW}${SYMBOL_ARROW}${RESET} ${BOLD}Already installed (${skipped_count}):${RESET}"
        for item in "${SKIPPED_ITEMS[@]}"; do
            echo -e "     ${DIM}•${RESET} $item"
        done
    fi

    # Show failures
    if [[ $failed_count -gt 0 ]]; then
        echo ""
        echo -e "  ${RED}${SYMBOL_FAIL}${RESET} ${BOLD}Failed (${failed_count}):${RESET}"
        for item in "${FAILED_ITEMS[@]}"; do
            echo -e "     ${DIM}•${RESET} $item"
        done
    fi

    # Show summary counts
    echo ""
    local total=$((installed_count + skipped_count + failed_count))
    if [[ $installed_count -eq 0 ]] && [[ $failed_count -eq 0 ]]; then
        echo -e "  ${DIM}Everything was already installed - nothing to do!${RESET}"
    fi

    echo ""
    if [[ -n "$LOG_FILE" ]]; then
        echo -e "  ${DIM}Install log:${RESET} ${CYAN}$LOG_FILE${RESET}"
    fi
    echo -e "  ${SYMBOL_ROCKET} ${BOLD}Next steps:${RESET}"
    if [[ "${SHELL_CHANGED:-false}" == true ]]; then
        echo -e "     1. ${BOLD}Log out and log back in${RESET} to start using zsh"
        echo -e "     2. Enjoy your new setup!"
    elif [[ "$SHELL" != *"zsh"* ]]; then
        echo -e "     1. Run ${CYAN}zsh${RESET} to start using your new shell"
        echo -e "        Or log out and back in if zsh is your default shell"
        echo -e "     2. Enjoy your new setup!"
    else
        echo -e "     1. Restart your terminal (or run: ${CYAN}source ~/.zshrc${RESET})"
        echo -e "     2. Enjoy your new setup!"
    fi
    echo ""
}
