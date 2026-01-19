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
source "$INSTALL_DIR/lazygit.sh"
source "$INSTALL_DIR/nerd-fonts.sh"
source "$INSTALL_DIR/git-confirmer.sh"

# ============================================================================
# Main Installation
# ============================================================================

main() {
    ui_init "$UI_MODE" "$UI_THEME"
    ui_clear
    log_init

    print_header "ZSH-Manager: New Machine Setup"
    if [[ "$UI_WARN_GUM_MISSING" == true ]]; then
        print_warning "gum requested but not found; falling back to classic UI."
    fi

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

    # Calculate step count based on platform
    # Base: 14 steps (rust, uv, python, nvm, node, npm, omz, plugins, tailscale, copyparty, nerd-fonts, symlink, topgrade, done)
    # APT: +3 (apt repos, apt packages, docker) = 17
    # Brew macOS: +5 (brew, taps, packages, lazygit, casks) = 19
    # Brew Linux: +6 (brew, taps, packages, lazygit, casks, docker) = 20
    local STEP_COUNT=17
    if [[ "$IS_MACOS" == false ]] && [[ "$USE_APT" == false ]]; then
        STEP_COUNT=18
    fi
    if [[ "$USE_APT" == false ]]; then
        STEP_COUNT=$((STEP_COUNT + 1))
        STEP_COUNT=$((STEP_COUNT + 1))
    fi
    if [[ "$IS_MACOS" == true ]] || [[ "$IS_UBUNTU" == true ]]; then
        STEP_COUNT=$((STEP_COUNT + 1))
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

        install_brew_taps
        progress_update "Brew taps configured"

        install_brew_packages
        progress_update "Brew packages installed"

        install_lazygit
        progress_update "Lazygit installed"

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

    progress_update "Topgrade configured"

    if [[ "$IS_MACOS" == true ]] || [[ "$IS_UBUNTU" == true ]]; then
        install_git_confirmer_optional
        progress_update "git_confirmer checked"
    fi

    # Done!
    print_summary
}

# Run main function
main "$@"
