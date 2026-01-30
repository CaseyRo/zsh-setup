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
    echo "ERROR: Do not run this script as root or with sudo."
    echo ""
    echo "The installer will prompt for sudo when needed (e.g., apt install)."
    echo "Running the entire script as root creates permission issues for user files."
    echo ""
    echo "Usage: ./install.sh"
    exit 1
fi

# ============================================================================
# Argument Parsing
# ============================================================================

export VERBOSE=false
export YES_TO_ALL=false
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
source "$INSTALL_DIR/tailscale.sh"
source "$INSTALL_DIR/network-mounts.sh"
source "$INSTALL_DIR/copyparty.sh"
source "$INSTALL_DIR/lazygit.sh"
source "$INSTALL_DIR/nerd-fonts.sh"
source "$INSTALL_DIR/git-confirmer.sh"
source "$INSTALL_DIR/mas.sh"
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
    # Show Matrix splash screen (if cmatrix/figlet available)
    show_splash

    ui_init "$UI_MODE" "$UI_THEME"
    ui_clear
    log_init

    print_header "ZSH-Setup: New Machine Setup"
    if [[ "$UI_WARN_GUM_MISSING" == true ]]; then
        print_warning "gum requested but not found; falling back to classic UI."
    fi

    cleanup_legacy_zsh_manager

    # Detect platform early for display
    local USE_APT=false
    local IS_MACOS=false
    local IS_UBUNTU=false
    local PLATFORM_NAME="Linux"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        IS_MACOS=true
        PLATFORM_NAME="macOS"
    elif should_use_apt; then
        USE_APT=true
        if is_raspberry_pi; then
            PLATFORM_NAME="Raspberry Pi"
        else
            PLATFORM_NAME="ARM Linux"
        fi
    fi
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* ]]; then
            IS_UBUNTU=true
        fi
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

    echo -e "  ${DIM}This script will install:${RESET}"
    if [[ "$USE_APT" == true ]]; then
        echo -e "  ${SYMBOL_BULLET} APT packages (git, gh, bat, ripgrep, fd, etc.)"
        echo -e "  ${SYMBOL_BULLET} Rust & Cargo (minimal - eza, zoxide, topgrade)"
        echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
    else
        echo -e "  ${SYMBOL_BULLET} Homebrew + CLI tools (git, gh, bat, eza, etc.)"
        echo -e "  ${SYMBOL_BULLET} Lazygit (Git TUI)"
        echo -e "  ${SYMBOL_BULLET} Rust & Cargo"
        if [[ "$IS_MACOS" == true ]]; then
            echo -e "  ${SYMBOL_BULLET} Mac App Store apps (via mas)"
        else
            echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
        fi
    fi
    echo -e "  ${SYMBOL_BULLET} NVM + Node.js stable + global packages (pm2, node-red)"
    echo -e "  ${SYMBOL_BULLET} uv + Python stable"
    echo -e "  ${SYMBOL_BULLET} Oh My Zsh + plugins"
    echo -e "  ${SYMBOL_BULLET} Tailscale (VPN mesh network)"
    echo -e "  ${SYMBOL_BULLET} Copyparty (portable file server)"
    echo -e "  ${SYMBOL_BULLET} Nerd Fonts (terminal glyphs for prompts)"
    echo -e "  ${SYMBOL_BULLET} ZSH-Setup configuration"
    if [[ "$IS_MACOS" == true ]] || [[ "$IS_UBUNTU" == true ]]; then
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

    # Detect OS
    print_section "System Detection"
    print_info "Detected: $PLATFORM_NAME"
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f /etc/os-release ]]; then
        source /etc/os-release
        print_info "Distribution: $PRETTY_NAME"
    fi
    if is_arm; then
        print_info "Architecture: ARM ($(uname -m))"
    fi
    if [[ "$USE_APT" == true ]]; then
        print_info "Install method: APT + minimal Cargo"
    else
        print_info "Install method: Homebrew + Cargo"
    fi

    # =========================================================================
    # Platform-specific package installation
    # =========================================================================

    if [[ "$USE_APT" == true ]]; then
        # ARM Linux (Raspberry Pi) - use APT
        setup_apt_repos

        install_apt_packages

        install_apt_packages_ubuntu

        install_docker_apt

    else
        # macOS or x86 Linux - use Homebrew
        install_homebrew

        install_brew_taps

        install_brew_packages

        install_lazygit

        install_brew_casks
        install_mas_apps

        # Docker for Linux (non-macOS) via Homebrew
        if [[ "$IS_MACOS" == false ]]; then
            install_brew_packages_linux
        fi
    fi

    # =========================================================================
    # Common installation (all platforms)
    # =========================================================================

    install_rust

    if [[ "$USE_APT" == true ]]; then
        install_cargo_packages_minimal
    else
        install_cargo_packages
    fi

    install_uv

    install_python_uv

    install_nvm

    install_node

    install_npm_global_packages

    install_oh_my_zsh

    install_zsh_plugins

    install_tailscale

    configure_tailscale

    configure_nfs_mount

    install_copyparty

    install_nerd_fonts

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

    if [[ "$IS_MACOS" == true ]] || [[ "$IS_UBUNTU" == true ]]; then
        install_git_confirmer_optional
    fi

    # Set zsh as default shell
    set_default_shell_zsh

    # Done!
    print_summary
}

# Run main function
main "$@"
