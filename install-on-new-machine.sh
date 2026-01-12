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
#   New Machine Setup Script
#   https://github.com/CaseyRo/zsh-manager
#
# ============================================================================

set -e

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
source "$INSTALL_DIR/oh-my-zsh.sh"
source "$INSTALL_DIR/tailscale.sh"

# ============================================================================
# Main Installation
# ============================================================================

main() {
    clear

    print_header "ZSH-Manager: New Machine Setup"

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
    echo -e "  ${SYMBOL_BULLET} NVM + Node.js LTS + global packages (pm2, node-red)"
    echo -e "  ${SYMBOL_BULLET} Oh My Zsh + plugins"
    echo -e "  ${SYMBOL_BULLET} Tailscale (VPN mesh network)"
    echo -e "  ${SYMBOL_BULLET} ZSH-Manager configuration"
    echo ""
    echo -e "  ${DIM}Safe to re-run - already installed items will be skipped.${RESET}"
    echo ""

    # Confirm before proceeding
    read -p "  Continue? [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
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
    # Base: 9 steps (rust, nvm, node, npm, omz, plugins, tailscale, symlink, done)
    # APT: +3 (apt repos, apt packages, docker) = 12
    # Brew macOS: +3 (brew, packages, casks) = 12
    # Brew Linux: +4 (brew, packages, casks, docker) = 13
    local STEP_COUNT=12
    if [[ "$IS_MACOS" == false ]] && [[ "$USE_APT" == false ]]; then
        STEP_COUNT=13
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

    # Setup zsh-manager symlink
    print_section "ZSH-Manager Configuration"
    ZSHRC_TARGET="$HOME/.zshrc"

    if [[ -L "$ZSHRC_TARGET" ]] && [[ "$(readlink "$ZSHRC_TARGET")" == "$SCRIPT_DIR/.zshrc" ]]; then
        print_skip "zshrc symlink"
    else
        if [[ -f "$ZSHRC_TARGET" ]] || [[ -L "$ZSHRC_TARGET" ]]; then
            print_step "Backing up existing .zshrc"
            mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            print_success "Backup created"
        fi

        print_step "Creating symlink"
        ln -s "$SCRIPT_DIR/.zshrc" "$ZSHRC_TARGET"
        print_success "~/.zshrc → $SCRIPT_DIR/.zshrc"
    fi

    progress_update "ZSH-Manager configured"

    # Done!
    print_summary
}

# Run main function
main "$@"
