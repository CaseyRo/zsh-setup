# shellcheck shell=bash
# ============================================================================
# Package Lists
# ============================================================================
# Edit these arrays to customize what gets installed on new machines.
# ============================================================================

# Homebrew taps (additional repositories)
BREW_TAPS=(
    "gromgit/brewtils"    # taproom and other brew utilities
    "marcus/tap"          # sidecar TUI for dev workflows
    "mutagen-io/mutagen"  # file sync for remote/container dev
)

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
    "jq"         # JSON processor
    "yq"         # YAML processor (like jq for YAML)
    "wget"       # file downloader
    "tree"       # directory tree viewer
    "tlrc"       # tldr pages client (Rust, fast)
    "yt-dlp"     # YouTube downloader
)

# Homebrew packages for macOS dev machines only
BREW_PACKAGES_MAC_DEV=(
    "go"         # Go programming language (needed for go install tools)
    "gromgit/brewtils/taproom" # interactive TUI for Homebrew
    "mactop"     # Apple Silicon system monitor (top for Mac)
    "php"        # PHP runtime
    "composer"   # PHP package manager
    "wp-cli"     # WordPress CLI
    "marcus/tap/sidecar"                 # TUI for git, AI agents, tasks, file browsing
    "mutagen-io/mutagen/mutagen"         # file sync for remote/container dev
    "mutagen-io/mutagen/mutagen-compose" # docker compose integration
    "zellij"     # terminal multiplexer / workspace
)

# Homebrew casks (macOS GUI apps, skipped on Linux)
BREW_CASKS=(
    "raycast"    # spotlight replacement & productivity launcher
    "setapp"     # app subscription service
)

# Homebrew casks for macOS dev machines only
BREW_CASKS_MAC_DEV=(
    "claude"     # Claude desktop app
    "claude-code" # Claude Code CLI
    "orbstack"   # Docker replacement for macOS
    "utm"        # VM manager
    "cursor"     # IDE
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
    "git-delta"  # better git diffs (syntax highlighting, side-by-side)
    "du-dust"    # better disk usage viewer (dust)
    "hyperfine"  # command benchmarking tool
    "procs"      # modern ps replacement
    "sd"         # intuitive sed alternative
    "tokei"      # code line counter by language
    "bandwhich"  # bandwidth usage by process
    "llmfit"     # LLM toolkit CLI
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
    "jq"         # JSON processor
    "wget"       # file downloader
    "tree"       # directory tree viewer
    "htop"       # interactive process viewer
)

# Cargo packages for APT systems - only what's NOT available via apt
CARGO_PACKAGES_APT=(
    "zoxide"     # smarter cd (not in apt)
    "eza"        # modern ls (not in apt)
    "topgrade"   # system updater (not in apt)
    "cargo-cache" # manage cargo cache disk usage (not in apt)
    "zellij"     # terminal multiplexer / workspace (not in apt)
    "llmfit"     # LLM toolkit CLI
)

# APT packages only for Ubuntu (not Raspberry Pi)
APT_PACKAGES_UBUNTU=(
    "cockpit"    # web-based server management UI
)

# ============================================================================
# Go packages (installed via go install, macOS dev machines only)
# ============================================================================
GO_PACKAGES=(
    "github.com/osteele/mutagui@latest"  # TUI for managing Mutagen sync sessions
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
    "vercel"       # Vercel CLI (deploy, dev, env management)
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
