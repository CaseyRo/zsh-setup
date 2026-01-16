#!/bin/bash
# ============================================================================
#
#   ███████╗███████╗██╗  ██╗      ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
#   ╚══███╔╝██╔════╝██║  ██║      ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
#     ███╔╝ ███████╗███████║█████╗██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
#    ███╔╝  ╚════██║██╔══██║╚════╝██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
#   ███████╗███████║██║  ██║      ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
#   ╚══════╝╚══════╝╚═╝  ╚═╝      ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
#
#   ZSH-Manager Setup Script
#   https://github.com/CaseyRo/zsh-manager
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
# Argument Parsing
# ============================================================================

export VERBOSE=false
UI_MODE="${ZSH_MANAGER_UI:-auto}"
UI_THEME="${ZSH_MANAGER_THEME:-classic}"

show_help() {
    echo "ZSH-Manager Setup Script"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Show detailed output from all commands"
    echo "  -h, --help       Show this help message"
    echo "  --ui MODE        UI mode: auto, classic, gum, plain"
    echo "  --theme THEME    UI theme: classic, mono, minimal"
    echo ""
    echo "Safe to re-run - already installed items will be skipped."
    echo ""
    echo "Environment:"
    echo "  NO_COLOR         Disable color output"
    echo "  ZSH_MANAGER_UI   Same as --ui"
    echo "  ZSH_MANAGER_THEME Same as --theme"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
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
    # Reset terminal scroll region if we were interrupted
    printf "\033[r" 2>/dev/null || true
    printf "\033[?25h" 2>/dev/null || true  # Show cursor
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
source "$INSTALL_DIR/copyparty.sh"
source "$INSTALL_DIR/nerd-fonts.sh"

# ============================================================================
# Main Installation
# ============================================================================

main() {
    ui_init "$UI_MODE" "$UI_THEME"
    ui_clear

    print_header "ZSH-Manager: New Machine Setup"
    if [[ "$UI_WARN_GUM_MISSING" == true ]]; then
        print_warning "gum requested but not found; falling back to classic UI."
    fi

    # Detect platform early for display
    local USE_APT=false
    local IS_MACOS=false
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
    ui_set_context "$PLATFORM_NAME"

    echo -e "  ${DIM}This script will install:${RESET}"
    if [[ "$USE_APT" == true ]]; then
        echo -e "  ${SYMBOL_BULLET} APT packages (git, gh, bat, ripgrep, fd, etc.)"
        echo -e "  ${SYMBOL_BULLET} Rust & Cargo (minimal - eza, zoxide, topgrade)"
        echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
    else
        echo -e "  ${SYMBOL_BULLET} Homebrew + CLI tools (git, gh, bat, eza, etc.)"
        echo -e "  ${SYMBOL_BULLET} Rust & Cargo"
        if [[ "$IS_MACOS" == false ]]; then
            echo -e "  ${SYMBOL_BULLET} Docker & Docker Compose"
        fi
    fi
    echo -e "  ${SYMBOL_BULLET} NVM + Node.js stable + global packages (pm2, node-red)"
    echo -e "  ${SYMBOL_BULLET} uv + Python stable"
    echo -e "  ${SYMBOL_BULLET} Oh My Zsh + plugins"
    echo -e "  ${SYMBOL_BULLET} Tailscale (VPN mesh network)"
    echo -e "  ${SYMBOL_BULLET} Copyparty (portable file server)"
    echo -e "  ${SYMBOL_BULLET} Nerd Fonts (terminal glyphs for prompts)"
    echo -e "  ${SYMBOL_BULLET} ZSH-Manager configuration"
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

    # Calculate step count based on platform
    # Base: 13 steps (rust, uv, python, nvm, node, npm, omz, plugins, tailscale, copyparty, nerd-fonts, symlink, done)
    # APT: +3 (apt repos, apt packages, docker) = 16
    # Brew macOS: +3 (brew, packages, casks) = 16
    # Brew Linux: +4 (brew, packages, casks, docker) = 17
    local STEP_COUNT=16
    if [[ "$IS_MACOS" == false ]] && [[ "$USE_APT" == false ]]; then
        STEP_COUNT=17
    fi
    progress_init $STEP_COUNT

    # =========================================================================
    # Platform-specific package installation
    # =========================================================================

    if [[ "$USE_APT" == true ]]; then
        # ARM Linux (Raspberry Pi) - use APT
        setup_apt_repos
        progress_update "APT repositories configured"

        install_apt_packages
        progress_update "APT packages installed"

        install_docker_apt
        progress_update "Docker installed"

    else
        # macOS or x86 Linux - use Homebrew
        install_homebrew
        progress_update "Homebrew installed"

        install_brew_packages
        progress_update "Brew packages installed"

        install_brew_casks
        progress_update "Brew casks installed"

        # Docker for Linux (non-macOS) via Homebrew
        if [[ "$IS_MACOS" == false ]]; then
            install_brew_packages_linux
            progress_update "Docker installed"
        fi
    fi

    # =========================================================================
    # Common installation (all platforms)
    # =========================================================================

    install_rust
    progress_update "Rust installed"

    if [[ "$USE_APT" == true ]]; then
        install_cargo_packages_minimal
        progress_update "Cargo packages installed (ARM)"
    else
        install_cargo_packages
        progress_update "Cargo packages installed"
    fi

    install_uv
    progress_update "uv installed"

    install_python_uv
    progress_update "Python installed"

    install_nvm
    progress_update "NVM installed"

    install_node
    progress_update "Node.js installed"

    install_npm_global_packages
    progress_update "NPM packages installed"

    install_oh_my_zsh
    progress_update "Oh My Zsh installed"

    install_zsh_plugins
    progress_update "ZSH plugins installed"

    install_tailscale
    progress_update "Tailscale installed"

    install_copyparty
    progress_update "Copyparty installed"

    install_nerd_fonts
    progress_update "Nerd Fonts installed"

    # Setup zsh-manager symlink
    print_section "ZSH-Manager Configuration"
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

    progress_update "ZSH-Manager configured"

    # Done!
    print_summary
}

# Run main function
main "$@"
