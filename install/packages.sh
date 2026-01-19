# ============================================================================
# Package Lists
# ============================================================================
# Edit these arrays to customize what gets installed on new machines.
# ============================================================================

# Homebrew taps (additional repositories)
BREW_TAPS=()

# Homebrew packages (installed via brew install)
# Only packages not available via cargo or that work better via brew
BREW_PACKAGES=(
    "zsh"
    "git"        # version control
    "gh"         # GitHub CLI
    "1password-cli" # 1Password CLI
    "fzf"        # fuzzy finder (keybindings install better via brew)
    "byobu"      # terminal multiplexer
    "fastfetch"  # fast system info (faster alternative to hyfetch)
    "btop"       # modern system monitor (successor to bashtop)
)

# Additional brew packages for Linux only (skipped on macOS)
BREW_PACKAGES_LINUX=(
    "docker"
    "docker-compose"
)

# Homebrew casks (macOS GUI apps, skipped on Linux)
BREW_CASKS=(
    "raycast"    # spotlight replacement & productivity launcher
)

# Cargo packages (installed via cargo install)
# Prefer cargo for Rust-based CLI tools
CARGO_PACKAGES=(
    "bat"        # cat with syntax highlighting
    "zoxide"     # smarter cd
    "eza"        # modern ls replacement
    "ripgrep"    # fast grep (rg)
    "fd-find"    # fast find (fd)
    "topgrade"   # system updater
)

# ============================================================================
# APT Packages (for ARM Linux / Raspberry Pi)
# ============================================================================
# Pre-built packages are much faster than compiling via cargo on ARM

APT_PACKAGES=(
    "zsh"
    "git"
    "gh"         # GitHub CLI (needs repo setup)
    "fzf"
    "byobu"
    "bat"
    "fd-find"
    "ripgrep"
    "fastfetch"  # may fall back to neofetch
    "btop"       # modern system monitor (successor to bashtop)
)

# Cargo packages for ARM - only what's NOT available via apt
CARGO_PACKAGES_ARM=(
    "zoxide"     # smarter cd (not in apt)
    "eza"        # modern ls (not in apt)
    "topgrade"   # system updater (not in apt)
)

# ============================================================================
# Global npm packages (installed via npm install -g)
# ============================================================================
NPM_GLOBAL_PACKAGES=(
    "pm2"
    "node-red"
)

# npm packages only for macOS and Ubuntu (not ARM/Raspberry Pi)
NPM_GLOBAL_PACKAGES_DESKTOP=(
    "nori-ai-cli"  # Nori AI CLI assistant
)

# ============================================================================
# Nerd Fonts (for terminal glyphs/icons)
# ============================================================================
# These provide special characters used by prompts like Powerlevel10k, btop, etc.
# Only installed on desktop systems (macOS, Linux with display), skipped on headless.
# Font names should match GitHub release names (without "NerdFont" suffix).
# See: https://github.com/ryanoasis/nerd-fonts/releases
NERD_FONTS=(
    "FiraMono"       # clean, readable mono font
    "JetBrainsMono"  # excellent for coding, ligature support
    "Meslo"          # recommended by Powerlevel10k
)
