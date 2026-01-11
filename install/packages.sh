# ============================================================================
# Package Lists
# ============================================================================
# Edit these arrays to customize what gets installed on new machines.
# ============================================================================

# Homebrew packages (installed via brew install)
# Only packages not available via cargo or that work better via brew
BREW_PACKAGES=(
    "zsh"
    "git"        # version control
    "gh"         # GitHub CLI
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
    # Add any GUI apps here, e.g.:
    # "iterm2"
    # "visual-studio-code"
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
