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
| Shell | ZSH, Starship prompt, carapace (completions), atuin (history) |
| File & search | eza, bat, fd, ripgrep, fzf, zoxide, yazi (file manager) |
| System | btop, fastfetch, duf / dysk (disk), procs, dust, bandwhich |
| Data & net | jq, yq, jnv (interactive JSON), xh (HTTP), ouch (archives) |
| Docs | glow (markdown), tlrc (tldr) |
| Dev tools | git, gh (GitHub CLI), lazygit, jj (Jujutsu VCS), git-delta |
| Languages | mise (Node.js + runtimes), Rust/Cargo, uv + Python |
| Services | Docker, Tailscale, Copyparty, Syncthing |
| Fonts | Nerd Fonts (FiraMono, JetBrainsMono, Meslo) - desktop only |

### Platform-specific installation

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| macOS | Homebrew + Cargo | No Docker |
| Raspberry Pi / ARM Linux | APT + Cargo | Docker via APT, pre-built packages where available |

### Modern CLI tools & shortcuts

Newer tools come with guarded aliases (defined in `modules/common/modern-cli.sh`; each only activates if the tool is installed):

| Shortcut | Expands to | Tool |
|----------|-----------|------|
| `y` | open file manager, `cd` to where you quit | yazi |
| `md <file>` / `readme` | render markdown in the terminal | glow |
| `pack` / `unpack` | compress / extract any archive format | ouch |
| `http` / `https` | HTTPie-style HTTP client | xh |
| `jqi <file>` | interactive/live JSON filtering | jnv |
| `df` | richer disk-usage table | dysk (Linux) / duf |
| `jjs` / `jjl` / `jjd` | `jj status` / `log` / `diff` | jj (Jujutsu) |

**Node & other runtimes** are managed by [mise](https://mise.jdx.dev) (replaces NVM): versions auto-switch per directory from `mise.toml` / `.tool-versions` / `.node-version`. **carapace** adds argument-aware completions for hundreds of CLIs.

### What they look like

<table>
  <tr>
    <td align="center"><b>Starship</b> — the prompt<br><img src="https://raw.githubusercontent.com/starship/starship/main/media/demo.gif" width="380"></td>
    <td align="center"><b>btop</b> — system monitor<br><img src="https://raw.githubusercontent.com/aristocratos/btop/main/Img/normal.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>lazygit</b> — Git TUI<br><img src="https://user-images.githubusercontent.com/8456633/174470852-339b5011-5800-4bb9-a628-ff230aa8cd4e.png" width="380"></td>
    <td align="center"><b>git-delta</b> — better diffs<br><img src="https://user-images.githubusercontent.com/52205/147996902-9829bd3f-cd33-466e-833e-49a6f3ebd623.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>atuin</b> — shell history<br><img src="https://raw.githubusercontent.com/atuinsh/atuin/main/demo.gif" width="380"></td>
    <td align="center"><b>zellij</b> — terminal workspace<br><img src="https://raw.githubusercontent.com/zellij-org/zellij/main/assets/demo.gif" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>glow</b> — markdown reader<br><img src="https://stuff.charm.sh/glow/glow-banner-github.gif" width="380"></td>
    <td align="center"><b>yazi</b> — file manager<br><br><a href="https://yazi-rs.github.io/">▶ live demo &amp; screenshots →</a></td>
  </tr>
</table>

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
