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
source "$INSTALL_DIR/lazygit.sh"
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

    INSTALLED_SOMETHING=true
    install_lazygit
}

upgrade_apt_packages() {
    if ! command_exists apt-get; then
        return 0
    fi

    local need_update=false

    for package in "${APT_PACKAGES[@]}"; do
        if ! dpkg -s "$package" &>/dev/null 2>&1; then
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

    # Mirror install_cargo_packages_minimal(): on apt hosts the host-only list
    # (yazi, jj, topgrade, …) is part of the install, so it must roll out via
    # auto-update too — otherwise those tools only ever arrive on a full
    # ./install.sh run.
    local packages
    if should_use_apt; then
        packages=("${CARGO_PACKAGES_APT[@]}")
        if ! is_docker && [[ ${#CARGO_PACKAGES_APT_HOST[@]} -gt 0 ]]; then
            packages+=("${CARGO_PACKAGES_APT_HOST[@]}")
        fi
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

# mise supersedes NVM. On existing machines the nvm.sh runtime modules are
# disabled by this update, so install mise AND provision Node here — otherwise
# `node` would vanish until the next full install.sh run.
upgrade_mise() {
    local mise=""
    if command_exists mise; then
        mise="mise"
    elif [[ -x "$HOME/.local/bin/mise" ]]; then
        mise="$HOME/.local/bin/mise"
    else
        INSTALLED_SOMETHING=true
        echo -e "${SYMBOL_PACKAGE} Installing new tool: ${BOLD}mise${RESET}"
        if [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
            brew install mise &>/dev/null && mise="mise"
        else
            curl -fsSL https://mise.run 2>/dev/null | sh &>/dev/null
            [[ -x "$HOME/.local/bin/mise" ]] && mise="$HOME/.local/bin/mise"
        fi
        if [[ -n "$mise" ]]; then
            echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} mise installed"
        else
            echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to install mise"
            return 0
        fi
    fi

    # Provision a global Node LTS if mise isn't managing one yet.
    export PATH="$HOME/.local/bin:$PATH"
    if ! "$mise" which node &>/dev/null; then
        INSTALLED_SOMETHING=true
        echo -e "${SYMBOL_PACKAGE} Provisioning ${BOLD}Node.js LTS${RESET} via mise"
        "$mise" use -g node@lts &>/dev/null && \
            echo -e "  ${GREEN}${SYMBOL_SUCCESS}${RESET} Node.js installed" || \
            echo -e "  ${RED}${SYMBOL_FAIL}${RESET} Failed to provision Node.js"
        "$mise" reshim &>/dev/null || true
    fi
    export PATH="$HOME/.local/share/mise/shims:$PATH"
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
                local cask_name
                cask_name=$(get_brew_cask_name "$font")
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

# Whether the sudo-requiring upgrade steps (apt, system-wide binaries) can run.
# macOS upgrades never need sudo. On Linux we need either cached/passwordless
# sudo, or an interactive tty we're allowed to prompt on — the background
# auto-update sets UPGRADE_NONINTERACTIVE=1 to forbid prompting, so it skips
# the sudo steps but the user-space steps (mise/node, cargo, npm, fonts) below
# still run.
_upgrade_can_sudo() {
    [[ "$OSTYPE" == "darwin"* ]] && return 0
    sudo -n true 2>/dev/null && return 0
    [[ "${UPGRADE_NONINTERACTIVE:-0}" != 1 && -t 0 ]]
}

run_upgrade() {
    upgrade_log_rotate

    local can_sudo=false
    _upgrade_can_sudo && can_sudo=true

    # --- Steps that write system-wide and need root --------------------------
    if should_use_apt; then
        if [[ "$can_sudo" == true ]]; then
            upgrade_apt_packages
            upgrade_lazygit
            upgrade_tailscale
        else
            echo -e "${SYMBOL_PACKAGE} Skipping apt/lazygit/tailscale (no sudo); run ${BOLD}zsh-update${RESET} to install them."
        fi
    else
        upgrade_brew_taps
        upgrade_brew_packages
        upgrade_lazygit
        upgrade_tailscale
    fi

    # Drop cached sudo credentials before user-space operations (must not run as root)
    sudo -k 2>/dev/null || true

    # --- User-space steps — always safe to run, no sudo required -------------
    upgrade_cargo_packages
    upgrade_mise
    upgrade_npm_packages
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
