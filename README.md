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
| File & search | eza, bat, fd, ripgrep, fzf, zoxide |
| System | btop, fastfetch |
| Data | jq |
| Editor | helix (`hx`, modal editor + Cobalt2 theme; becomes `$EDITOR`) |
| Editor tooling (`--dev`) | language servers for shell, TOML, YAML, JSON, Markdown, Python, TS/JS, Go, PHP, Docker; shellcheck runs inline while you type |
| Dev tools | git, gh (GitHub CLI), git-delta, herdr (AI agent workspace), topgrade (updater) |
| Languages | mise (Node.js + runtimes), Rust/Cargo, uv + Python |
| Services | Docker, Tailscale, Copyparty |
| Fonts | Nerd Fonts (FiraMono, JetBrainsMono, Meslo) - desktop only |

### Platform-specific installation

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| macOS | Homebrew + Cargo | No Docker |
| Raspberry Pi / ARM Linux | APT + Cargo | Docker via APT, pre-built packages where available |

**Node & other runtimes** are managed by [mise](https://mise.jdx.dev) (replaces NVM): versions auto-switch per directory from `mise.toml` / `.tool-versions` / `.node-version`. **carapace** adds argument-aware completions for hundreds of CLIs.

### What they look like

<!-- markdownlint-disable MD033 MD045 -->
<!-- The demo gallery below is a deliberate HTML table: markdown tables cannot
     do the two-column image grid, and the images are upstream screenshots with
     no useful alt text to add. Both rules stay on for the rest of the file. -->

_Prompt & shell history_

<table>
  <tr>
    <td align="center"><b>Starship</b> — the prompt<br><img src="https://raw.githubusercontent.com/starship/starship/main/media/demo.gif" width="380"></td>
    <td align="center"><b>atuin</b> — shell history<br><img src="https://raw.githubusercontent.com/atuinsh/atuin/main/demo.gif" width="380"></td>
  </tr>
</table>

_Files & navigation_

<table>
  <tr>
    <td align="center"><b>eza</b> — modern ls<br><img src="https://raw.githubusercontent.com/eza-community/eza/main/docs/images/screenshots.png" width="380"></td>
    <td align="center"><b>fzf</b> — fuzzy finder<br><img src="https://raw.githubusercontent.com/junegunn/i/master/fzf-preview.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>fd</b> — fast find<br><img src="docs/gifs/fd.gif" width="380"></td>
    <td></td>
  </tr>
</table>

_Viewing & search_

<table>
  <tr>
    <td align="center"><b>bat</b> — cat w/ highlighting<br><img src="https://i.imgur.com/rGsdnDe.png" width="380"></td>
    <td align="center"><b>ripgrep</b> — fast grep<br><img src="https://burntsushi.net/stuff/ripgrep1.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>jq</b> — JSON processor<br><img src="docs/gifs/jq.gif" width="380"></td>
    <td></td>
  </tr>
</table>

_Editor_

<table>
  <tr>
    <td align="center"><b>helix</b> — modal editor (hx)<br><img src="https://raw.githubusercontent.com/helix-editor/helix/master/screenshot.png" width="380"></td>
    <td></td>
  </tr>
</table>

_Git & dev_

<table>
  <tr>
    <td align="center"><b>git-delta</b> — better diffs<br><img src="https://user-images.githubusercontent.com/52205/81058545-a5725f80-8e9c-11ea-912e-d21954586a44.png" width="380"></td>
    <td align="center"><b>herdr</b> — agent workspace<br><img src="docs/gifs/herdr.gif" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>topgrade</b> — update everything<br><img src="docs/gifs/topgrade.gif" width="380"></td>
    <td></td>
  </tr>
</table>

_System & monitoring_

<table>
  <tr>
    <td align="center"><b>btop</b> — system monitor<br><img src="https://raw.githubusercontent.com/aristocratos/btop/main/Img/normal.png" width="380"></td>
    <td align="center"><b>fastfetch</b> — system info<br><img src="https://raw.githubusercontent.com/fastfetch-cli/fastfetch/dev/screenshots/example1.png" width="380"></td>
  </tr>
</table>

_Multiplexer, runtimes & HTTP_

<table>
  <tr>
    <td align="center"><b>mise</b> — version manager<br><img src="https://raw.githubusercontent.com/jdx/mise/main/docs/tapes/demo.gif" width="380"></td>
    <td></td>
  </tr>
</table>

<!-- markdownlint-enable MD033 MD045 -->

> Non-visual utilities (nothing meaningful to screenshot): `zoxide`, `carapace`.

### Tool reference & links

Want to dig into any of these? Each links to its source repo.

**Shell & prompt**

| Tool | What it does |
|------|--------------|
| [starship](https://github.com/starship/starship) | Fast, customizable cross-shell prompt |
| [atuin](https://github.com/atuinsh/atuin) | Synced, searchable, encrypted shell history (Ctrl+R) |
| [carapace](https://github.com/carapace-sh/carapace-bin) | Argument-aware completions for 1000+ CLIs |

**Files & navigation**

| Tool | What it does |
|------|--------------|
| [eza](https://github.com/eza-community/eza) | Modern `ls` with icons & git status |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` that learns your habits |
| [fzf](https://github.com/junegunn/fzf) | General-purpose fuzzy finder |
| [fd](https://github.com/sharkdp/fd) | Fast, friendly `find` |

**Viewing, search & text**

| Tool | What it does |
|------|--------------|
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting & git integration |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Extremely fast recursive `grep` (`rg`) |
| [jq](https://github.com/jqlang/jq) | Command-line JSON processor |

**Editor**

| Tool | What it does |
|------|--------------|
| [helix](https://github.com/helix-editor/helix) | Post-modern modal editor (`hx`), built-in LSP + tree-sitter, no plugins needed |

**Git & dev**

| Tool | What it does |
|------|--------------|
| [git-delta](https://github.com/dandavison/delta) | Syntax-highlighted git diffs & pager |
| [mise](https://github.com/jdx/mise) | Runtime/version manager (Node, Python, …) |
| [herdr](https://herdr.dev) | Terminal workspace manager for AI coding agents |
| [hyperfine](https://github.com/sharkdp/hyperfine) | Command-line benchmarking |

**System & monitoring**

| Tool | What it does |
|------|--------------|
| [btop](https://github.com/aristocratos/btop) | Resource monitor (CPU/mem/net/disk) |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | Fast system info (neofetch successor) |

**Multiplexer, HTTP & misc**

| Tool | What it does |
|------|--------------|
| [topgrade](https://github.com/topgrade-rs/topgrade) | One command to update everything |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Media downloader |

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
./install.sh --install-warp  # Install Warp terminal + config (macOS GUI machines)
./install.sh --skip-warp     # Skip Warp terminal install/config
./install.sh --mac-dev-machine     # Enable macOS dev machine profile
./install.sh --no-mac-dev-machine  # Disable macOS dev machine profile
./install.sh --skip-mac-networked  # Skip macOS networked services
./install.sh --allow-low-battery   # Allow install below 25% battery
./install.sh --dev                 # Shorthand for --mac-dev-machine
./install.sh --light               # Server/VPS profile (aliases: --server, --vps; implies --skip-splash)
./install.sh --skip-splash         # No splash screen
./install.sh --fix-home-ownership  # Repair \$HOME ownership before installing
```

### Notes (macOS)

- If sudo is unavailable, Homebrew installs to `~/homebrew` and the setup adds that path automatically.
- macOS app installs (casks/MAS) and networked services are opt-in during install.
- macOS dev profile installs: OrbStack, UTM, Cursor, PHP/Composer/WP-CLI, PHPCS+WPCS, and Cursor settings/extensions seeding.

### Warp terminal (macOS, opt-in)

On GUI-capable macOS machines the installer offers Warp as a standalone choice (prompt, or `--install-warp` / `--skip-warp`). It is independent of the dev profile and is **not** affected by `--skip-casks`. When enabled it:

- installs Warp and the official Cascadia font cask (`font-cascadia-code`, which provides the `Cascadia Code NF` family);
- seeds the **Cobalt2** themes to `~/.warp/themes/` — both plain `Cobalt2` and **`Cobalt2 Dim`**, a lower-contrast variant (off-white foreground instead of pure `#fff`) that avoids halation/eye-strain on high-density Retina displays; the seeded config defaults to `Cobalt2 Dim`, and either is switchable in Warp's theme picker;
- nudges macOS font smoothing to medium (`defaults write dev.warp.Warp-Stable AppleFontSmoothing -int 2`) so thin glyph strokes don't shimmer on Retina (takes effect on next Warp relaunch);
- writes a full starter `~/.warp/settings.toml` from `configs/warp/settings.toml` (font `Cascadia Code NF`, `Cobalt2 Dim` theme, vertical tabs, `aurora` app icon, block cursor, ligatures, notification prefs, a secret-redaction regex list, **SSH Warpification** so remote sessions inherit Warp's UX, and **session restore** for persistent tabs) **only if one does not already exist** — Warp rewrites this file at runtime, so an existing config is never clobbered. The `__HOME__` placeholder in the seed is expanded to your `$HOME`;
- seeds repo-owned **workflows** from `configs/warp/workflows/*.yaml` to `~/.warp/workflows/` (parameterized commands in Warp's command palette — `zsh-setup • reinstall/doctor`, `git • delete merged branches/sync & prune`). Idempotent; the repo is the source of truth.

This snapshots the parts of a "looks cool" Warp setup that Warp's own account sync doesn't reliably bootstrap on a fresh machine (custom theme files + a baseline `settings.toml` + local workflows). To re-capture after tweaking Warp's appearance, copy your live `~/.warp/settings.toml` back over `configs/warp/settings.toml`, restoring the `__HOME__` placeholder for the theme paths.

For resilient/persistent SSH (Warp has no mosh integration), the package lists include [`mosh`](https://mosh.org) — sessions that survive roaming, sleep, and disconnects.

Warp uses its own input editor and bypasses zsh's ZLE, so the zsh-abbr Claude shortcuts (`cl`, `clc`, …) don't expand there. `modules/common/warp.sh` mirrors them as plain aliases under `TERM_PROGRAM=WarpTerminal` so they work in Warp too.

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
│   └── <name>.sh
└── macos/
    └── <name>.sh
```

Modules in each folder load in lexicographic order. The `zz_` prefix is **reserved** for tail-init modules that must run last — currently `zz_abbr.sh` (needs the zsh-abbr plugin), `zz_atuin.sh` (overrides fzf's Ctrl+R), `zz_completions.sh` (lets zsh-autocomplete own `compinit`), and `zz_zoxide.sh` (must be strictly last to override `cd`). Don't prefix your own modules with `zz_`.

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
