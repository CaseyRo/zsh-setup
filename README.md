# ZSH-Setup

A cross-platform ZSH configuration framework for Linux, macOS, and Windows (WSL).

## Quick Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-setup/main/bootstrap.sh)"
```

This installs everything on a fresh machine. Safe to re-run - already installed items are skipped.

### What gets installed

| Category | Tools |
|----------|-------|
| Shell | ZSH, Starship prompt |
| CLI tools | bat, eza, ripgrep, fd, fzf, zoxide, btop, fastfetch, atuin |
| Dev tools | git, gh (GitHub CLI), lazygit |
| Languages | Rust/Cargo, NVM + Node.js, uv + Python |
| Services | Docker, Tailscale, Copyparty |
| Fonts | Nerd Fonts (FiraMono, JetBrainsMono, Meslo) - desktop only |

### Platform-specific installation

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| macOS | Homebrew + Cargo | No Docker |
| Raspberry Pi / ARM Linux | APT + Cargo | Docker via APT, pre-built packages where available |

## Manual Installation

```bash
git clone git@github.com:CaseyRo/zsh-setup.git ~/.zsh-setup
cd ~/.zsh-setup
./install.sh
```

### Options

```bash
./install.sh -y              # Answer yes to all prompts
./install.sh -v              # Verbose output
./install.sh --ui gum        # Use gum for prompts (if installed)
./install.sh --theme minimal # Minimal color theme
./install.sh --skip-casks    # Skip macOS Homebrew casks
./install.sh --skip-mas      # Skip macOS App Store installs
./install.sh --mac-dev-machine     # Enable macOS dev machine profile
./install.sh --no-mac-dev-machine  # Disable macOS dev machine profile
./install.sh --skip-mac-networked  # Skip macOS networked services
./install.sh --allow-low-battery   # Allow install below 25% battery
```

### Notes (macOS)

- If sudo is unavailable, Homebrew installs to `~/homebrew` and the setup adds that path automatically.
- macOS app installs (casks/MAS) and networked services are opt-in during install.
- macOS dev profile installs: OrbStack, UTM, Cursor, PHP/Composer/WP-CLI, PHPCS+WPCS, and Cursor settings/extensions seeding.

## Directory Structure

```
zsh-setup/
├── .zshrc                    # Main ZSH config (symlinked to ~/.zshrc)
├── install.sh                # Full setup script
├── bootstrap.sh              # Remote one-liner installer
├── install/                  # Installation modules
│   └── packages.sh           # Package lists (customize here)
├── preload_configs/          # Loaded before modules
│   ├── common/               # All platforms
│   ├── linux/                # Linux-specific
│   ├── macos/                # macOS-specific
│   └── windows/              # Windows/WSL-specific
└── modules/                  # Loaded after preload_configs
    ├── common/               # All platforms
    ├── linux/                # Linux-specific
    ├── macos/                # macOS-specific
    └── windows/              # Windows/WSL-specific
```

## How It Works

1. **OS Detection**: Automatically detects your OS and loads appropriate configs
2. **Load Order**: `preload_configs/common/` → `preload_configs/{os}/` → `modules/common/` → `modules/{os}/`
3. **Symlink**: Your `~/.zshrc` points to the framework's `.zshrc`

## Customization

### Adding modules

Place scripts in `modules/common/` (all platforms) or `modules/{os}/` (OS-specific):

```bash
modules/
├── common/
│   ├── aliases.sh         # Shared aliases
│   └── functions.sh       # Shared functions
├── linux/
│   └── linux_aliases.sh
└── macos/
    └── macos_shortcuts.sh
```

Modules in each folder load in lexicographic order. The `zz_` prefix is **reserved** for tail-init modules that must run last — currently `zz_atuin.sh` (overrides fzf's Ctrl+R) and `zz_zoxide.sh` (must be strictly last to override `cd`). Don't prefix your own modules with `zz_`.

### Ignoring files

Prefix with `#` to skip loading:

```bash
modules/common/#old_aliases.sh    # Ignored
modules/#deprecated/              # Entire folder ignored
```

### Environment variables

Create `~/.env.sh` for private environment variables:

```bash
export MY_API_KEY="secret"
```

### Customizing packages

Edit `install/packages.sh` to add/remove packages from the installation.

## Atuin (Shell History Sync)

[Atuin](https://docs.atuin.sh/) replaces your shell history with a searchable, encrypted, and synced database. Ctrl+R opens Atuin's fuzzy search instead of the default zsh history.

History syncs to a self-hosted Atuin server on the Tailscale mesh — no data leaves the private network.

### First-time setup

After running `install.sh`, log in to sync history across machines:

```bash
atuin login -u casey
# Enter the encryption key from 1Password when prompted
atuin import auto    # Import existing shell history
atuin sync           # First sync
```

## License

MIT
