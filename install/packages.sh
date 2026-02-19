# shellcheck shell=bash
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
    "figlet"     # ASCII art text banners
    "cmatrix"    # Matrix rain effect for splash screen
    "toilet"     # ASCII art text generator
)

# Homebrew casks (macOS GUI apps, skipped on Linux)
BREW_CASKS=(
    "raycast"    # spotlight replacement & productivity launcher
    "setapp"     # app subscription service
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
    "cargo-cache" # manage cargo cache disk usage
)

# ============================================================================
# APT Packages (for Debian/Ubuntu Linux)
# ============================================================================
# Pre-built packages are much faster than compiling via cargo

APT_PACKAGES=(
    "build-essential"  # gcc, make, linker - required for cargo compilation
    "zsh"
    "git"
    "gh"         # GitHub CLI (needs repo setup)
    "fzf"
    "byobu"
    "bat"
    "fd-find"
    "ripgrep"
    "btop"       # modern system monitor (successor to bashtop)
    "micro"      # simple terminal text editor
    "unzip"      # required for Nerd Fonts installation
    "nfs-common" # NFS client for network mounts
    "figlet"     # ASCII art text banners
    "cmatrix"    # Matrix rain effect for splash screen
    "toilet"     # ASCII art text generator
)

# Cargo packages for APT systems - only what's NOT available via apt
CARGO_PACKAGES_APT=(
    "zoxide"     # smarter cd (not in apt)
    "eza"        # modern ls (not in apt)
    "topgrade"   # system updater (not in apt)
    "cargo-cache" # manage cargo cache disk usage (not in apt)
)

# APT packages only for Ubuntu (not Raspberry Pi)
APT_PACKAGES_UBUNTU=(
    "cockpit"    # web-based server management UI
)

# ============================================================================
# Global npm packages (installed via npm install -g)
# ============================================================================
NPM_GLOBAL_PACKAGES=(
    "pm2"
    "@fission-ai/openspec"  # spec-driven development for AI assistants
)

# Networked npm packages (macOS requires explicit opt-in)
NPM_GLOBAL_PACKAGES_NETWORKED=(
    "node-red"
)

# npm packages only for macOS and Ubuntu (not ARM/Raspberry Pi)
NPM_GLOBAL_PACKAGES_DESKTOP=(
    "nori-ai-cli"  # Nori AI CLI assistant
)

# ============================================================================
# Mac App Store apps (installed via mas on macOS only)
# ============================================================================
# Get app IDs with: mas search <name> or mas list (for installed apps)
MAS_APPS=(
    "1569813296"  # 1Password for Safari
    "1160435653"  # AutoMounter
    "1102004240"  # iHosts
    "904280696"   # Things
    "1490879410"  # TrashMe 3
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
