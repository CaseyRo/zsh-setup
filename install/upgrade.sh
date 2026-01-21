#!/bin/bash
# ============================================================================
# ZSH-Setup: Upgrade Script
# ============================================================================
# Installs any new packages added to packages.sh after a git pull.
# Designed to run silently and only output when installing new tools.
# ============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"

# Source utilities and package lists
source "$INSTALL_DIR/utils.sh"
source "$INSTALL_DIR/packages.sh"
source "$INSTALL_DIR/nerd-fonts.sh"
source "$INSTALL_DIR/git-confirmer.sh"

# Track if we installed anything
INSTALLED_SOMETHING=false

# ============================================================================
# Quiet Installation Functions
# ============================================================================

upgrade_brew_taps() {
    if ! command_exists brew; then
        return 0
    fi

    if [[ ${#BREW_TAPS[@]} -eq 0 ]]; then
        return 0
    fi

    for tap in "${BREW_TAPS[@]}"; do
        if ! brew tap | grep -qx "$tap"; then
            INSTALLED_SOMETHING=true
            echo -e "${SYMBOL_PACKAGE} Tapping new repository: ${BOLD}$tap${RESET}"
            brew tap "$tap" &>/dev/null && \
                echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $tap tapped" || \
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to tap $tap"
        fi
    done
}

upgrade_brew_packages() {
    if ! command_exists brew; then
        return 0
    fi

    for package in "${BREW_PACKAGES[@]}"; do
        if ! brew list "$package" &>/dev/null; then
            INSTALLED_SOMETHING=true
            echo -e "${SYMBOL_PACKAGE} Installing new package: ${BOLD}$package${RESET}"
            brew install "$package" &>/dev/null && \
                echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $package installed" || \
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $package"
        fi
    done

    # Linux-only packages
    if [[ "$OSTYPE" != "darwin"* ]]; then
        for package in "${BREW_PACKAGES_LINUX[@]}"; do
            if ! brew list "$package" &>/dev/null; then
                INSTALLED_SOMETHING=true
                echo -e "${SYMBOL_PACKAGE} Installing new package: ${BOLD}$package${RESET}"
                brew install "$package" &>/dev/null && \
                    echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $package installed" || \
                    echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $package"
            fi
        done
    fi

    # macOS casks
    if [[ "$OSTYPE" == "darwin"* ]]; then
        for cask in "${BREW_CASKS[@]}"; do
            if ! brew list --cask "$cask" &>/dev/null; then
                INSTALLED_SOMETHING=true
                echo -e "${SYMBOL_PACKAGE} Installing new cask: ${BOLD}$cask${RESET}"
                brew install --cask "$cask" &>/dev/null && \
                    echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $cask installed" || \
                    echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $cask"
            fi
        done
    fi
}

upgrade_lazygit() {
    if command_exists lazygit; then
        return 0
    fi

    if ! command_exists brew; then
        return 0
    fi

    INSTALLED_SOMETHING=true
    echo -e "${SYMBOL_PACKAGE} Installing new package: ${BOLD}lazygit${RESET}"
    brew install "lazygit" &>/dev/null && \
        echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} Lazygit installed" || \
        echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install Lazygit"
}

upgrade_apt_packages() {
    if ! command_exists apt-get; then
        return 0
    fi

    local need_update=false

    for package in "${APT_PACKAGES[@]}"; do
        if ! dpkg -l "$package" &>/dev/null 2>&1; then
            if [[ "$need_update" == false ]]; then
                sudo apt-get update -qq &>/dev/null
                need_update=true
            fi
            INSTALLED_SOMETHING=true
            echo -e "${SYMBOL_PACKAGE} Installing new package: ${BOLD}$package${RESET}"
            sudo apt-get install -y -qq "$package" &>/dev/null && \
                echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $package installed" || \
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $package"
        fi
    done
}

upgrade_cargo_packages() {
    if ! command_exists cargo; then
        return 0
    fi

    local packages
    if should_use_apt; then
        packages=("${CARGO_PACKAGES_ARM[@]}")
    else
        packages=("${CARGO_PACKAGES[@]}")
    fi

    for package in "${packages[@]}"; do
        if ! cargo install --list 2>/dev/null | grep -q "^$package "; then
            INSTALLED_SOMETHING=true
            echo -e "${SYMBOL_PACKAGE} Installing new cargo package: ${BOLD}$package${RESET}"
            cargo install "$package" &>/dev/null && \
                echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $package installed" || \
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $package"
        fi
    done
}

upgrade_npm_packages() {
    if ! command_exists npm; then
        return 0
    fi

    for package in "${NPM_GLOBAL_PACKAGES[@]}"; do
        if ! npm list -g "$package" &>/dev/null 2>&1; then
            INSTALLED_SOMETHING=true
            echo -e "${SYMBOL_PACKAGE} Installing new npm package: ${BOLD}$package${RESET}"
            npm install -g "$package" &>/dev/null && \
                echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $package installed" || \
                echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $package"
        fi
    done
}

upgrade_tailscale() {
    # Skip if already installed
    if command_exists tailscale; then
        return 0
    fi

    # On macOS, check if app is installed (cask doesn't add CLI to PATH immediately)
    if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/Applications/Tailscale.app" ]]; then
        return 0
    fi

    INSTALLED_SOMETHING=true
    echo -e "${SYMBOL_PACKAGE} Installing new package: ${BOLD}tailscale${RESET}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Install via Homebrew cask
        brew install --cask tailscale &>/dev/null && \
            echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} Tailscale installed" || \
            echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install Tailscale"
    else
        # Linux: Use official install script
        curl -fsSL https://tailscale.com/install.sh | sh &>/dev/null && \
            echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} Tailscale installed" || \
            echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install Tailscale"
    fi
}

upgrade_nerd_fonts() {
    # Skip on headless systems
    if ! has_display; then
        return 0
    fi

    # Skip if no fonts configured
    if [[ ${#NERD_FONTS[@]} -eq 0 ]]; then
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Install via Homebrew cask
        for font in "${NERD_FONTS[@]}"; do
            if ! is_nerd_font_installed "$font"; then
                INSTALLED_SOMETHING=true
                local cask_name=$(get_brew_cask_name "$font")
                echo -e "${SYMBOL_PACKAGE} Installing new font: ${BOLD}$font Nerd Font${RESET}"
                brew install --cask "$cask_name" &>/dev/null && \
                    echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $font Nerd Font installed" || \
                    echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $font Nerd Font"
            fi
        done
    else
        # Linux: Download from GitHub releases
        for font in "${NERD_FONTS[@]}"; do
            if ! is_nerd_font_installed "$font"; then
                INSTALLED_SOMETHING=true
                echo -e "${SYMBOL_PACKAGE} Installing new font: ${BOLD}$font Nerd Font${RESET}"
                install_nerd_font_linux "$font" &>/dev/null && \
                    echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} $font Nerd Font installed" || \
                    echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install $font Nerd Font"
            fi
        done
    fi
}

# ============================================================================
# Main Upgrade Function
# ============================================================================

run_upgrade() {
    # Determine platform
    if should_use_apt; then
        upgrade_apt_packages
    else
        upgrade_brew_taps
        upgrade_brew_packages
        upgrade_lazygit
    fi

    upgrade_cargo_packages
    upgrade_npm_packages
    upgrade_tailscale
    upgrade_nerd_fonts
    upgrade_git_confirmer

    if [[ "$INSTALLED_SOMETHING" == true ]]; then
        echo -e "${GREEN}${SYMBOL_SUCCESS}${RESET} Upgrade complete!"
    fi
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_upgrade
fi
