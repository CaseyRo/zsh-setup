#!/bin/bash
# ============================================================================
#
#   ███████╗███████╗██╗  ██╗      ███████╗███████╗████████╗██╗   ██╗██████╗
#   ╚══███╔╝██╔════╝██║  ██║      ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
#     ███╔╝ ███████╗███████║█████╗███████╗█████╗     ██║   ██║   ██║██████╔╝
#    ███╔╝  ╚════██║██╔══██║╚════╝╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
#   ███████╗███████║██║  ██║      ███████║███████╗   ██║   ╚██████╔╝██║
#   ╚══════╝╚══════╝╚═╝  ╚═╝      ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
#
#   ZSH-Setup Setup Script
#   https://github.com/CaseyRo/zsh-setup
#
#   Usage: ./install.sh [OPTIONS]
#
#   Options:
#     -v, --verbose    Show detailed output from all commands
#     -h, --help       Show this help message
#
# ============================================================================

set -e

# ============================================================================
# Root/Sudo Check - Prevent running entire script as root
# ============================================================================

if [[ $EUID -eq 0 ]]; then
    # Allow running as root inside Docker containers
    if [[ -f /.dockerenv ]] || grep -qw docker /proc/1/cgroup 2>/dev/null || \
       grep -qw docker /proc/self/mountinfo 2>/dev/null; then
        # In Docker: define sudo as a passthrough (already root)
        sudo() { "$@"; }
        export -f sudo
        # Auto-enable non-interactive mode in Docker
        export YES_TO_ALL=true
    else
        echo ""
        echo "WARNING: Running as root is not recommended."
        echo "The installer needs a regular user account to set up dotfiles correctly."
        echo ""
        echo "Options:"
        echo "  1) Create a new user and continue as that user"
        echo "  2) Exit and re-run as a regular user"
        echo ""
        printf "Choose [1/2]: "
        read -r ROOT_CHOICE

        if [[ "$ROOT_CHOICE" == "1" ]]; then
            printf "Enter username to create: "
            read -r NEW_USERNAME

            if [[ -z "$NEW_USERNAME" ]]; then
                echo "ERROR: Username cannot be empty."
                exit 1
            fi

            # Validate username (lowercase, alphanumeric, hyphens, underscores)
            if [[ ! "$NEW_USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
                echo "ERROR: Invalid username. Use lowercase letters, numbers, hyphens, underscores."
                echo "       Must start with a letter."
                exit 1
            fi

            if id "$NEW_USERNAME" &>/dev/null; then
                echo "User '$NEW_USERNAME' already exists. Switching to that user..."
            else
                echo "Creating user '$NEW_USERNAME'..."

                if command -v useradd &>/dev/null; then
                    useradd -m -s /bin/bash "$NEW_USERNAME"
                elif command -v adduser &>/dev/null; then
                    adduser --disabled-password --gecos "" "$NEW_USERNAME"
                else
                    echo "ERROR: Cannot create user (no useradd or adduser found)."
                    exit 1
                fi

                # Set a password
                echo "Set a password for '$NEW_USERNAME':"
                passwd "$NEW_USERNAME"

                # Grant sudo access
                if command -v usermod &>/dev/null; then
                    if getent group sudo &>/dev/null; then
                        usermod -aG sudo "$NEW_USERNAME"
                    elif getent group wheel &>/dev/null; then
                        usermod -aG wheel "$NEW_USERNAME"
                    fi
                fi

                echo ""
                echo "User '$NEW_USERNAME' created with sudo access."
            fi

            # Ensure the new user can access the script directory
            SCRIPT_DIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            NEW_HOME="$(eval echo "~$NEW_USERNAME")"

            # If the script is in /root, copy it to the new user's home
            if [[ "$SCRIPT_DIR_ROOT" == /root* ]]; then
                TARGET_DIR="$NEW_HOME/.zsh-setup"
                echo "Copying zsh-setup to $TARGET_DIR..."
                cp -r "$SCRIPT_DIR_ROOT" "$TARGET_DIR"
                chown -R "$NEW_USERNAME":"$NEW_USERNAME" "$TARGET_DIR"
                SCRIPT_DIR_ROOT="$TARGET_DIR"
            else
                # Make sure the user can read the script directory
                chmod -R o+rX "$SCRIPT_DIR_ROOT" 2>/dev/null || true
            fi

            echo ""
            echo "Re-running installer as '$NEW_USERNAME'..."
            echo ""
            exec su - "$NEW_USERNAME" -c "cd '$SCRIPT_DIR_ROOT' && bash ./install.sh $*"
        else
            echo ""
            echo "Re-run as a regular user:"
            echo "  ./install.sh"
            exit 1
        fi
    fi
fi

# ============================================================================
# Argument Parsing
# ============================================================================

export VERBOSE=false
export YES_TO_ALL=false
export SKIP_BREW_CASKS=false
export SKIP_MAS_APPS=false
export SKIP_MAC_APPS=false
export SKIP_MAC_NETWORKED=false
export ENABLE_MAC_NETWORKED=false
export ALLOW_MAC_NETWORKED_SERVICES=false
export IS_MAC_DEV_MACHINE=false
export MAC_DEV_MACHINE_EXPLICIT=false
export USE_STARSHIP=true
export ALLOW_LOW_BATTERY=false
export SKIP_SPLASH=false
export LIGHT_MODE=false
UI_MODE="${ZSH_SETUP_UI:-${ZSH_MANAGER_UI:-auto}}"
UI_THEME="${ZSH_SETUP_THEME:-${ZSH_MANAGER_THEME:-classic}}"

show_help() {
    echo "ZSH-Setup Setup Script"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -y, --yes        Answer yes to all prompts"
    echo "  -v, --verbose    Show detailed output from all commands"
    echo "  -h, --help       Show this help message"
    echo "  --skip-casks     Skip Homebrew cask installs on macOS"
    echo "  --skip-mas       Skip Mac App Store installs on macOS"
    echo "  --skip-mac-apps  Skip all macOS app installs (casks + mas)"
    echo "  --skip-mac-networked  Skip macOS networked services (e.g., Tailscale, Node-RED)"
    echo "  --enable-mac-networked  Install macOS networked services without prompting"
    echo "  --dev                Enable dev machine profile installs"
    echo "  --mac-dev-machine    Alias for --dev"
    echo "  --no-mac-dev-machine  Disable dev machine profile installs"
    echo "  --allow-low-battery  Allow install to proceed below 25% battery"
    echo "  --skip-splash        Skip the intro splash screen"
    echo "  --light              Minimal server/VPS install (no Rust, prebuilt bins)"
    echo "  --server, --vps      Aliases for --light"
    echo "  --ui MODE        UI mode: auto, classic, gum, plain"
    echo "  --theme THEME    UI theme: classic, mono, minimal"
    echo ""
    echo "Safe to re-run - already installed items will be skipped."
    echo ""
    echo "Environment:"
    echo "  NO_COLOR         Disable color output"
    echo "  ZSH_SETUP_UI     Same as --ui"
    echo "  ZSH_SETUP_THEME  Same as --theme"
    echo "  ZSH_MANAGER_UI   Legacy alias for ZSH_SETUP_UI"
    echo "  ZSH_MANAGER_THEME Legacy alias for ZSH_SETUP_THEME"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            export YES_TO_ALL=true
            shift
            ;;
        -v|--verbose)
            export VERBOSE=true
            shift
            ;;
        --skip-casks)
            export SKIP_BREW_CASKS=true
            shift
            ;;
        --skip-mas)
            export SKIP_MAS_APPS=true
            shift
            ;;
        --skip-mac-apps)
            export SKIP_MAC_APPS=true
            shift
            ;;
        --skip-mac-networked)
            export SKIP_MAC_NETWORKED=true
            shift
            ;;
        --enable-mac-networked)
            export ENABLE_MAC_NETWORKED=true
            shift
            ;;
        --mac-dev-machine)
            # Legacy alias for --dev
            export IS_MAC_DEV_MACHINE=true
            export MAC_DEV_MACHINE_EXPLICIT=true
            shift
            ;;
        --no-mac-dev-machine)
            export IS_MAC_DEV_MACHINE=false
            export MAC_DEV_MACHINE_EXPLICIT=true
            shift
            ;;
        --allow-low-battery)
            export ALLOW_LOW_BATTERY=true
            shift
            ;;
        --skip-splash)
            export SKIP_SPLASH=true
            shift
            ;;
        --dev)
            export IS_MAC_DEV_MACHINE=true
            export MAC_DEV_MACHINE_EXPLICIT=true
            shift
            ;;
        --light|--server|--vps)
            export LIGHT_MODE=true
            export SKIP_SPLASH=true
            shift
            ;;
        --ui)
            UI_MODE="$2"
            shift 2
            ;;
        --ui=*)
            UI_MODE="${1#*=}"
            shift
            ;;
        --theme)
            UI_THEME="$2"
            shift 2
            ;;
        --theme=*)
            UI_THEME="${1#*=}"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Conflict checks
if [[ "$LIGHT_MODE" == true ]] && [[ "$IS_MAC_DEV_MACHINE" == true ]]; then
    echo "ERROR: --dev and --light/--server/--vps cannot be used together."
    echo "  --dev is for full dev machine setups."
    echo "  --light is for minimal server/VPS installs."
    exit 1
fi

# Cleanup on exit/interrupt
cleanup_on_exit() {
    # Show cursor (keep this for safety)
    printf "\033[?25h" 2>/dev/null || true
}
trap cleanup_on_exit EXIT INT TERM

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/install"

# Source utilities and package lists
source "$INSTALL_DIR/utils.sh"
source "$INSTALL_DIR/packages.sh"
source "$INSTALL_DIR/brew.sh"
source "$INSTALL_DIR/apt.sh"
source "$INSTALL_DIR/rust.sh"
source "$INSTALL_DIR/nvm.sh"
source "$INSTALL_DIR/uv.sh"
source "$INSTALL_DIR/oh-my-zsh.sh"
source "$INSTALL_DIR/starship.sh"
source "$INSTALL_DIR/tailscale.sh"
source "$INSTALL_DIR/network-mounts.sh"
source "$INSTALL_DIR/copyparty.sh"
source "$INSTALL_DIR/lazygit.sh"
source "$INSTALL_DIR/nerd-fonts.sh"
source "$INSTALL_DIR/git-confirmer.sh"
source "$INSTALL_DIR/mas.sh"
source "$INSTALL_DIR/go.sh"
source "$INSTALL_DIR/php-dev.sh"
source "$INSTALL_DIR/cursor.sh"
source "$INSTALL_DIR/dev-repos.sh"
source "$INSTALL_DIR/prebuilt-bins.sh"
source "$INSTALL_DIR/splash.sh"

# ============================================================================
# Main Installation
# ============================================================================

cleanup_legacy_zsh_manager() {
    local legacy_dir="${ZSH_MANAGER_DIR:-$HOME/.zsh-manager}"
    local legacy_state="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-manager"
    local current_dir="$SCRIPT_DIR"
    local legacy_real=""
    local current_real=""

    if [[ -d "$legacy_dir" ]]; then
        legacy_real="$(cd "$legacy_dir" 2>/dev/null && pwd -P)"
    fi
    current_real="$(cd "$current_dir" 2>/dev/null && pwd -P)"

    if [[ -n "$legacy_real" ]] && [[ "$legacy_real" != "$current_real" ]]; then
        print_section "Legacy Cleanup"
        print_step "Removing legacy zsh-manager install"
        rm -rf "$legacy_dir"
        print_success "Removed $legacy_dir"
    fi

    if [[ -d "$legacy_state" ]]; then
        print_step "Removing legacy zsh-manager state logs"
        rm -rf "$legacy_state"
        print_success "Removed $legacy_state"
    fi
}

main() {
    if [[ "$SKIP_SPLASH" != true ]]; then
        show_splash || true
    fi

    ui_init "$UI_MODE" "$UI_THEME"
    log_init

    # Read persisted install state (unless overridden by CLI flags)
    local STATE_FILE="$SCRIPT_DIR/.install-state"

    # Migrate legacy .prompt-choice → .install-state
    if [[ -f "$SCRIPT_DIR/.prompt-choice" ]] && [[ ! -f "$STATE_FILE" ]]; then
        local legacy_choice
        legacy_choice=$(cat "$SCRIPT_DIR/.prompt-choice" 2>/dev/null)
        echo "PROMPT_CHOICE=$legacy_choice" > "$STATE_FILE"
        rm -f "$SCRIPT_DIR/.prompt-choice"
        print_info "Migrated .prompt-choice → .install-state"
    fi

    if [[ -f "$STATE_FILE" ]]; then
        # Read dev machine choice
        if [[ "$MAC_DEV_MACHINE_EXPLICIT" != true ]]; then
            local saved_dev
            saved_dev=$(grep '^IS_DEV_MACHINE=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)
            if [[ "$saved_dev" == "true" ]]; then
                IS_MAC_DEV_MACHINE=true
            elif [[ "$saved_dev" == "false" ]]; then
                IS_MAC_DEV_MACHINE=false
            fi
        fi
        # Read networked services choice
        if [[ "$SKIP_MAC_NETWORKED" != true ]] && [[ "$ENABLE_MAC_NETWORKED" != true ]]; then
            local saved_networked
            saved_networked=$(grep '^MAC_NETWORKED=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)
            if [[ "$saved_networked" == "true" ]]; then
                ALLOW_MAC_NETWORKED_SERVICES=true
            elif [[ "$saved_networked" == "false" ]]; then
                ALLOW_MAC_NETWORKED_SERVICES=false
            fi
        fi
    fi

    local zsh_setup_version="unknown"
    if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
        zsh_setup_version=$(cat "$SCRIPT_DIR/VERSION")
    fi
    print_header "ZSH-Setup v${zsh_setup_version}"
    if [[ "$UI_WARN_GUM_MISSING" == true ]]; then
        print_warning "gum requested but not found; falling back to classic UI."
    fi

    cleanup_legacy_zsh_manager

    # Detect platform early for display
    local USE_APT=false
    local IS_MACOS=false
    local IS_UBUNTU=false
    local PLATFORM_NAME="Linux"

    local IS_DOCKER=false
    if is_docker; then
        IS_DOCKER=true
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        IS_MACOS=true
        PLATFORM_NAME="macOS"
    elif should_use_apt; then
        USE_APT=true
        if is_raspberry_pi; then
            PLATFORM_NAME="Raspberry Pi"
        elif is_arm; then
            PLATFORM_NAME="ARM Linux"
        elif is_ubuntu; then
            PLATFORM_NAME="Ubuntu Linux"
        elif is_debian; then
            PLATFORM_NAME="Debian Linux"
        else
            PLATFORM_NAME="Linux"
        fi
    fi
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* ]]; then
            IS_UBUNTU=true
        fi
    fi
    if [[ "$IS_DOCKER" == true ]]; then
        PLATFORM_NAME="$PLATFORM_NAME (Docker)"
    fi
    ui_set_context "$PLATFORM_NAME"
    log_line "Platform: $PLATFORM_NAME"
    log_kv "OSTYPE" "$OSTYPE"
    log_kv "Architecture" "$(uname -m)"
    if [[ -f /etc/os-release ]]; then
        log_line "OS Release:"
        log_kv "PRETTY_NAME" "${PRETTY_NAME:-unknown}"
        log_kv "ID" "${ID:-unknown}"
        log_kv "ID_LIKE" "${ID_LIKE:-unknown}"
    fi
    if command_exists sysctl; then
        log_kv "CPU" "$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
        log_kv "MemoryBytes" "$(sysctl -n hw.memsize 2>/dev/null || echo unknown)"
    elif [[ -f /proc/cpuinfo ]]; then
        log_kv "CPU" "$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)"
    fi
    if [[ -f /proc/meminfo ]]; then
        log_kv "MemoryKB" "$(awk -F': ' '/MemTotal/ {print $2; exit}' /proc/meminfo)"
    fi
    log_kv "InstallMethod" "$([[ "$USE_APT" == true ]] && echo apt || echo brew)"
    log_kv "UI_MODE" "$UI_MODE"
    log_kv "UI_THEME" "$UI_THEME"
    log_kv "LIGHT_MODE" "$LIGHT_MODE"

    if [[ "$LIGHT_MODE" == true ]]; then
        echo -e "  ${BOLD}Light mode${RESET} ${DIM}(minimal server/VPS install)${RESET}"
        echo ""
    fi
    echo -e "  ${DIM}This script will install:${RESET}"
    if [[ "$LIGHT_MODE" == true ]]; then
        echo -e "  ${SYMBOL_BULLET} APT packages (git, gh, bat, ripgrep, fd, jq, btop, etc.)"
        echo -e "  ${SYMBOL_BULLET} zoxide & eza (prebuilt binaries)"
        echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
        echo -e "  ${SYMBOL_BULLET} Lazygit & Lazydocker (Git/Docker TUI)"
    elif [[ "$USE_APT" == true ]]; then
        echo -e "  ${SYMBOL_BULLET} APT packages (git, gh, bat, ripgrep, fd, etc.)"
        echo -e "  ${SYMBOL_BULLET} Rust & Cargo (minimal - eza, zoxide, topgrade)"
        echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
    else
        echo -e "  ${SYMBOL_BULLET} Homebrew + CLI tools (git, gh, bat, eza, etc.)"
        echo -e "  ${SYMBOL_BULLET} Lazygit (Git TUI)"
        echo -e "  ${SYMBOL_BULLET} Rust & Cargo"
        if [[ "$IS_MACOS" == true ]]; then
            echo -e "  ${SYMBOL_BULLET} Optional: Homebrew casks (macOS apps)"
            echo -e "  ${SYMBOL_BULLET} Optional: Mac App Store apps (via mas)"
        else
            echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
        fi
    fi
    if [[ "$LIGHT_MODE" == true ]]; then
        echo -e "  ${SYMBOL_BULLET} NVM + Node.js stable + global packages (pm2)"
    else
        echo -e "  ${SYMBOL_BULLET} NVM + Node.js stable + global packages (pm2, node-red)"
    fi
    echo -e "  ${SYMBOL_BULLET} uv + Python stable"
    echo -e "  ${SYMBOL_BULLET} Starship prompt + zsh plugins"
    echo -e "  ${SYMBOL_BULLET} Tailscale (VPN mesh network)"
    if [[ "$LIGHT_MODE" != true ]]; then
        echo -e "  ${SYMBOL_BULLET} Copyparty (portable file server)"
        echo -e "  ${SYMBOL_BULLET} Nerd Fonts (terminal glyphs for prompts)"
    fi
    echo -e "  ${SYMBOL_BULLET} ZSH-Setup configuration"
    if [[ "$LIGHT_MODE" != true ]] && { [[ "$IS_MACOS" == true ]] || [[ "$IS_UBUNTU" == true ]]; }; then
        echo -e "  ${SYMBOL_BULLET} Optional: git_confirmer (prompt at end)"
    fi
    echo ""
    echo -e "  ${DIM}Safe to re-run - already installed items will be skipped.${RESET}"
    echo ""

    # Confirm before proceeding
    if ! ui_confirm "Continue?"; then
        echo -e "  ${YELLOW}Aborted.${RESET}"
        exit 0
    fi

    if has_battery; then
        local battery_percent=""
        battery_percent=$(get_battery_percent || true)
        if [[ -n "$battery_percent" ]]; then
            if (( battery_percent < 25 )) && [[ "$ALLOW_LOW_BATTERY" != true ]]; then
                print_warning "Battery at ${battery_percent}% (below 25%). Aborting install."
                print_info "Re-run with --allow-low-battery to override."
                exit 1
            elif (( battery_percent < 50 )); then
                print_warning "Battery at ${battery_percent}% (below 50%). Consider plugging in."
            fi
        fi
    fi

    # macOS opt-in prompts (apps + networked services)
    if [[ "$IS_MACOS" == true ]]; then
        if [[ "$MAC_DEV_MACHINE_EXPLICIT" != true ]]; then
            if [[ "$YES_TO_ALL" == true ]]; then
                IS_MAC_DEV_MACHINE=false
                print_info "macOS dev machine profile: disabled by default in --yes mode"
            elif ui_confirm "Is this a dev machine?"; then
                IS_MAC_DEV_MACHINE=true
            else
                IS_MAC_DEV_MACHINE=false
            fi
        fi

        if [[ "$IS_MAC_DEV_MACHINE" == true ]]; then
            print_info "macOS dev machine profile enabled"
        fi
    fi

    print_info "Prompt: Starship"

    # Persist all user decisions to .install-state
    {
        echo "PROMPT_CHOICE=starship"
        echo "IS_DEV_MACHINE=$IS_MAC_DEV_MACHINE"
        echo "MAC_NETWORKED=$ALLOW_MAC_NETWORKED_SERVICES"
    } > "$SCRIPT_DIR/.install-state" 2>/dev/null || true

    if [[ "$IS_MACOS" == true ]]; then
        if [[ "$SKIP_MAC_APPS" == true ]]; then
            SKIP_BREW_CASKS=true
            SKIP_MAS_APPS=true
        else
            if [[ "$SKIP_BREW_CASKS" != true ]]; then
                if ! ui_confirm "Install Homebrew casks (macOS GUI apps)?"; then
                    SKIP_BREW_CASKS=true
                fi
            fi
            if [[ "$SKIP_MAS_APPS" != true ]]; then
                if ! ui_confirm "Install Mac App Store apps?"; then
                    SKIP_MAS_APPS=true
                fi
            fi
        fi

        if [[ "$SKIP_MAC_NETWORKED" == true ]]; then
            ALLOW_MAC_NETWORKED_SERVICES=false
        elif [[ "$ENABLE_MAC_NETWORKED" == true ]]; then
            ALLOW_MAC_NETWORKED_SERVICES=true
        else
            if ui_confirm "Install macOS networked services (Tailscale, Node-RED)?"; then
                ALLOW_MAC_NETWORKED_SERVICES=true
            else
                ALLOW_MAC_NETWORKED_SERVICES=false
            fi
        fi
    fi

    # Detect OS
    print_section "System Detection"
    print_info "Detected: $PLATFORM_NAME"
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /etc/os-release ]]; then
        source /etc/os-release
        print_info "Distribution: $PRETTY_NAME"
    fi
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "Architecture: $(uname -m)"
    fi
    if [[ "$LIGHT_MODE" == true ]]; then
        print_info "Install method: APT + prebuilt binaries (light mode)"
    elif [[ "$USE_APT" == true ]]; then
        print_info "Install method: APT + minimal Cargo"
    else
        print_info "Install method: Homebrew + Cargo"
    fi

    # =========================================================================
    # Platform-specific package installation
    # =========================================================================

    if [[ "$USE_APT" == true ]]; then
        # Debian/Ubuntu Linux - use APT
        setup_apt_repos

        install_apt_packages

        if [[ "$LIGHT_MODE" != true ]]; then
            install_apt_packages_ubuntu
        fi

        if [[ "$IS_DOCKER" != true ]]; then
            install_docker_apt
        else
            print_section "Docker"
            print_skip "Docker (already inside a container)"
            track_skipped "Docker (container)"
        fi

        install_lazygit

        if [[ "$IS_DOCKER" != true ]]; then
            install_lazydocker
        fi

        install_fastfetch_apt

    else
        # macOS - use Homebrew
        install_homebrew

        install_brew_taps

        install_brew_packages
        install_brew_packages_mac_dev

        install_lazygit

        install_lazydocker

        install_brew_casks
        install_brew_casks_mac_dev
        install_mas_apps
    fi

    # =========================================================================
    # Drop cached sudo credentials before user-space installers
    # =========================================================================
    # APT/Homebrew operations above may have cached sudo credentials.
    # User-space installers (Rust, NVM, uv, Starship) write to $HOME and
    # must NOT inherit elevated privileges, or they'll create root-owned files.
    sudo -k 2>/dev/null || true

    # =========================================================================
    # Common installation (all platforms)
    # =========================================================================

    if [[ "$LIGHT_MODE" == true ]]; then
        # Light mode: skip Rust/Cargo entirely, use prebuilt binaries
        print_section "Rust"
        print_skip "Rust/Cargo (light mode - using prebuilt binaries)"
        track_skipped "Rust (light mode)"

        install_prebuilt_bins
    else
        install_rust

        if [[ "$USE_APT" == true ]]; then
            install_cargo_packages_minimal
        else
            install_cargo_packages
        fi
    fi

    install_uv

    install_python_uv

    # Skip NVM if Node.js is already provided (e.g., Docker base image)
    if [[ "$IS_DOCKER" == true ]] && command_exists node; then
        print_section "NVM (Node Version Manager)"
        print_skip "NVM (Node.js $(node --version) provided by base image)"
        track_skipped "NVM (base image)"

        print_section "Node.js"
        print_skip "Node.js $(node --version) (from base image)"
        track_skipped "Node.js (base image)"
    else
        install_nvm

        install_node
    fi

    install_npm_global_packages

    # Dev repos: clone on dev machines and Docker containers
    if [[ "$LIGHT_MODE" != true ]]; then
        if [[ "$IS_MAC_DEV_MACHINE" == true ]] || [[ "$IS_DOCKER" == true ]]; then
            install_dev_repos
        fi

        install_php_dev_tools

        install_go_packages

        install_cursor_profile
    fi

    install_starship

    install_oh_my_zsh

    install_zsh_plugins

    if [[ "$IS_DOCKER" == true ]]; then
        print_section "Tailscale"
        print_skip "Tailscale (Docker container)"
        track_skipped "Tailscale (Docker)"
    elif [[ "$IS_MACOS" == true ]] && [[ "${ALLOW_MAC_NETWORKED_SERVICES}" != true ]]; then
        print_section "Tailscale"
        print_skip "Tailscale (macOS networked services disabled)"
        track_skipped "Tailscale (macOS networked services disabled)"
    else
        install_tailscale
    fi

    if [[ "$IS_DOCKER" != true ]]; then
        configure_tailscale
        if [[ "$LIGHT_MODE" != true ]]; then
            configure_nfs_mount
            install_copyparty
        fi
    else
        print_section "Network Mounts"
        print_skip "NFS mounts (Docker container)"
        track_skipped "NFS mounts (Docker)"
    fi

    if [[ "$LIGHT_MODE" != true ]]; then
        install_nerd_fonts
    fi

    # Setup zsh-setup symlink
    print_section "ZSH-Setup Configuration"
    ZSHRC_TARGET="$HOME/.zshrc"

    if [[ -L "$ZSHRC_TARGET" ]] && [[ "$(readlink "$ZSHRC_TARGET")" == "$SCRIPT_DIR/.zshrc" ]]; then
        print_skip "zshrc symlink"
        track_skipped "zshrc symlink"
    else
        if [[ -f "$ZSHRC_TARGET" ]] || [[ -L "$ZSHRC_TARGET" ]]; then
            print_step "Backing up existing .zshrc"
            mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            print_success "Backup created"
        fi

        print_step "Creating symlink"
        ln -s "$SCRIPT_DIR/.zshrc" "$ZSHRC_TARGET"
        print_success "~/.zshrc → $SCRIPT_DIR/.zshrc"
        track_installed "zshrc symlink"
    fi

    # Setup topgrade config symlink
    print_section "Topgrade Configuration"
    TOPGRADE_CONFIG_DIR="$HOME/.config"
    TOPGRADE_TARGET="$TOPGRADE_CONFIG_DIR/topgrade.toml"
    TOPGRADE_SOURCE="$SCRIPT_DIR/configs/topgrade.toml"

    if [[ -L "$TOPGRADE_TARGET" ]] && [[ "$(readlink "$TOPGRADE_TARGET")" == "$TOPGRADE_SOURCE" ]]; then
        print_skip "topgrade config symlink"
        track_skipped "topgrade config"
    else
        # Ensure ~/.config exists
        mkdir -p "$TOPGRADE_CONFIG_DIR"

        if [[ -f "$TOPGRADE_TARGET" ]] || [[ -L "$TOPGRADE_TARGET" ]]; then
            print_step "Backing up existing topgrade.toml"
            mv "$TOPGRADE_TARGET" "$TOPGRADE_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            print_success "Backup created"
        fi

        print_step "Creating topgrade config symlink"
        ln -s "$TOPGRADE_SOURCE" "$TOPGRADE_TARGET"
        print_success "~/.config/topgrade.toml → $TOPGRADE_SOURCE"
        track_installed "topgrade config"
    fi

    if [[ "$LIGHT_MODE" != true ]] && { [[ "$IS_MACOS" == true ]] || [[ "$IS_UBUNTU" == true ]]; }; then
        install_git_confirmer_optional
    fi

    # Set zsh as default shell
    set_default_shell_zsh

    # Done!
    print_summary
}

# Run main function
main "$@"
