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
| Shell | ZSH, Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting |
| CLI tools | bat, eza, ripgrep, fd, fzf, zoxide, btop, fastfetch |
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
```

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

## License

MIT
