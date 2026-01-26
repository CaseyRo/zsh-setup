#!/bin/bash
# ============================================================================
# Nerd Fonts Installation
# ============================================================================
# Installs Nerd Fonts for terminal glyph support (icons in prompts, etc.)
# Only runs on desktop systems (macOS, Linux with display), skipped on headless.
# ============================================================================

# Check if system has a display (not headless)
has_display() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS always has a display context
        return 0
    elif [[ -n "$DISPLAY" ]] || [[ -n "$WAYLAND_DISPLAY" ]]; then
        # Linux with X11 or Wayland
        return 0
    elif [[ -d /usr/share/fonts ]] && ! is_raspberry_pi; then
        # Linux with font directory and not a Pi (likely desktop)
        return 0
    fi
    return 1
}

# Check if a Nerd Font is installed
is_nerd_font_installed() {
    local font_name="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: check via brew or font directory
        if brew list --cask "font-${font_name}-nerd-font" &>/dev/null 2>&1; then
            return 0
        fi
        # Also check system font directories
        if find ~/Library/Fonts /Library/Fonts -name "*${font_name}*Nerd*" -print -quit 2>/dev/null | grep -q .; then
            return 0
        fi
    else
        # Linux: check common font directories
        if find ~/.local/share/fonts ~/.fonts /usr/share/fonts /usr/local/share/fonts \
            -name "*${font_name}*Nerd*" -print -quit 2>/dev/null | grep -q .; then
            return 0
        fi
        # Also check via fc-list if available
        if command_exists fc-list && fc-list | grep -qi "${font_name}.*nerd"; then
            return 0
        fi
    fi
    return 1
}

# Install a single Nerd Font on Linux
install_nerd_font_linux() {
    local font_name="$1"
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
    local font_dir="$HOME/.local/share/fonts/NerdFonts"
    local temp_dir=$(mktemp -d)

    mkdir -p "$font_dir"

    # Download and extract
    if curl -fsSL "$font_url" -o "$temp_dir/${font_name}.zip"; then
        # Check if unzip is available
        if ! command_exists unzip; then
            echo "unzip not installed, cannot extract fonts" >&2
            rm -rf "$temp_dir"
            return 1
        fi

        # Extract and verify
        if ! unzip -q "$temp_dir/${font_name}.zip" -d "$temp_dir/${font_name}" 2>/dev/null; then
            rm -rf "$temp_dir"
            return 1
        fi

        # Copy only .ttf and .otf files (skip Windows-compatible variants)
        find "$temp_dir/${font_name}" -type f \( -name "*.ttf" -o -name "*.otf" \) \
            ! -name "*Windows*" -exec cp {} "$font_dir/" \;
        rm -rf "$temp_dir"

        # Refresh font cache
        if command_exists fc-cache; then
            fc-cache -f "$font_dir" &>/dev/null
        fi
        return 0
    else
        rm -rf "$temp_dir"
        return 1
    fi
}

# Convert font name to Homebrew cask name
# Maps GitHub release names to Homebrew cask names
get_brew_cask_name() {
    local font="$1"
    case "$font" in
        FiraMono)       echo "font-fira-mono-nerd-font" ;;
        JetBrainsMono)  echo "font-jetbrains-mono-nerd-font" ;;
        Meslo)          echo "font-meslo-lg-nerd-font" ;;
        Hack)           echo "font-hack-nerd-font" ;;
        FiraCode)       echo "font-fira-code-nerd-font" ;;
        SourceCodePro)  echo "font-sauce-code-pro-nerd-font" ;;
        CascadiaCode)   echo "font-caskaydia-cove-nerd-font" ;;
        UbuntuMono)     echo "font-ubuntu-mono-nerd-font" ;;
        RobotoMono)     echo "font-roboto-mono-nerd-font" ;;
        *)
            # Fallback: convert CamelCase to kebab-case
            local cask_name=$(echo "$font" | sed 's/\([A-Z]\)/-\1/g' | sed 's/^-//' | tr '[:upper:]' '[:lower:]')
            echo "font-${cask_name}-nerd-font"
            ;;
    esac
}

install_nerd_fonts() {
    # Skip on headless systems
    if ! has_display; then
        return 0
    fi

    # Skip if no fonts configured
    if [[ ${#NERD_FONTS[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Nerd Fonts"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Install via Homebrew cask
        for font in "${NERD_FONTS[@]}"; do
            local cask_name=$(get_brew_cask_name "$font")
            if is_nerd_font_installed "$font"; then
                print_skip "$font Nerd Font"
                track_skipped "$font Nerd Font"
            else
                print_package "$font Nerd Font"
                if run_with_spinner "Installing $font Nerd Font" brew install --cask "$cask_name"; then
                    print_success "$font Nerd Font installed"
                    track_installed "$font Nerd Font"
                else
                    print_error "Failed to install $font Nerd Font"
                    track_failed "$font Nerd Font"
                fi
            fi
        done
    else
        # Linux: Download from GitHub releases
        for font in "${NERD_FONTS[@]}"; do
            if is_nerd_font_installed "$font"; then
                print_skip "$font Nerd Font"
                track_skipped "$font Nerd Font"
            else
                print_package "$font Nerd Font"
                if run_with_spinner "Installing $font Nerd Font" install_nerd_font_linux "$font"; then
                    print_success "$font Nerd Font installed"
                    track_installed "$font Nerd Font"
                else
                    print_error "Failed to install $font Nerd Font"
                    track_failed "$font Nerd Font"
                fi
            fi
        done
    fi
}
