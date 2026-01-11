#!/bin/bash
# ============================================================================
# ZSH-Manager: Upgrade Script
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

# Track if we installed anything
INSTALLED_SOMETHING=false

# ============================================================================
# Quiet Installation Functions
# ============================================================================

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

# ============================================================================
# Main Upgrade Function
# ============================================================================

run_upgrade() {
    # Determine platform
    if should_use_apt; then
        upgrade_apt_packages
    else
        upgrade_brew_packages
    fi

    upgrade_cargo_packages
    upgrade_npm_packages

    if [[ "$INSTALLED_SOMETHING" == true ]]; then
        echo -e "${GREEN}${SYMBOL_SUCCESS}${RESET} Upgrade complete!"
    fi
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_upgrade
fi
