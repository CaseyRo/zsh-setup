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
| Data & net | jq, yq, jnv (interactive JSON), xh (HTTP), ouch (archives), parsync (parallel sync) |
| Docs | glow (markdown), tlrc (tldr) |
| Dev tools | git, gh (GitHub CLI), lazygit, jj (Jujutsu VCS), git-delta, llmfit (LLM hardware checker) |
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
    <td align="center"><b>yazi</b> — file manager<br><br><a href="https://yazi-rs.github.io/">▶ live demo &amp; screenshots →</a></td>
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
    <td align="center"><b>glow</b> — markdown reader<br><img src="https://raw.githubusercontent.com/charmbracelet/glow/master/example.png" width="380"></td>
    <td align="center"><b>jnv</b> — interactive JSON<br><img src="https://raw.githubusercontent.com/ynqa/ynqa/master/demo/jnv.gif" width="380"></td>
  </tr>
</table>

_Git & dev_

<table>
  <tr>
    <td align="center"><b>lazygit</b> — Git TUI<br><img src="https://raw.githubusercontent.com/jesseduffield/lazygit/assets/viewing-commit-diffs.png" width="380"></td>
    <td align="center"><b>git-delta</b> — better diffs<br><img src="https://user-images.githubusercontent.com/52205/81058545-a5725f80-8e9c-11ea-912e-d21954586a44.png" width="380"></td>
  </tr>
</table>

_System & monitoring_

<table>
  <tr>
    <td align="center"><b>btop</b> — system monitor<br><img src="https://raw.githubusercontent.com/aristocratos/btop/main/Img/normal.png" width="380"></td>
    <td align="center"><b>fastfetch</b> — system info<br><img src="https://raw.githubusercontent.com/fastfetch-cli/fastfetch/dev/screenshots/example1.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>procs</b> — modern ps<br><img src="https://user-images.githubusercontent.com/4331004/55446625-5e5fce00-55fb-11e9-8914-69e8640d89d7.png" width="380"></td>
    <td align="center"><b>bandwhich</b> — network usage<br><img src="https://raw.githubusercontent.com/imsnif/bandwhich/main/res/demo.gif" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>dust</b> — disk usage tree<br><img src="https://raw.githubusercontent.com/bootandy/dust/master/media/snap.png" width="380"></td>
    <td align="center"><b>duf</b> — disk usage / df<br><img src="https://raw.githubusercontent.com/muesli/duf/master/duf.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>dysk</b> — filesystem table<br><img src="https://raw.githubusercontent.com/Canop/dysk/main/website/src/img/dysk.png" width="380"></td>
    <td></td>
  </tr>
</table>

_Multiplexer, runtimes & HTTP_

<table>
  <tr>
    <td align="center"><b>zellij</b> — terminal workspace<br><img src="https://raw.githubusercontent.com/zellij-org/zellij/main/assets/demo.gif" width="380"></td>
    <td align="center"><b>mise</b> — version manager<br><img src="https://raw.githubusercontent.com/jdx/mise/main/docs/tapes/demo.gif" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>xh</b> — HTTP client<br><img src="https://raw.githubusercontent.com/ducaale/xh/master/assets/xh-demo.gif" width="380"></td>
    <td></td>
  </tr>
</table>

> Non-visual utilities (nothing meaningful to screenshot): `zoxide`, `jj`, `carapace`, `fd`, `jq`/`yq`, `ouch`, `tlrc`, `sd`, `tokei`, `hyperfine`. See the table below for what each does.

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
| [yazi](https://github.com/sxyazi/yazi) | Blazing-fast terminal file manager |
| [fzf](https://github.com/junegunn/fzf) | General-purpose fuzzy finder |
| [fd](https://github.com/sharkdp/fd) | Fast, friendly `find` |

**Viewing, search & text**

| Tool | What it does |
|------|--------------|
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting & git integration |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Extremely fast recursive `grep` (`rg`) |
| [glow](https://github.com/charmbracelet/glow) | Render markdown in the terminal |
| [sd](https://github.com/chmln/sd) | Intuitive find-and-replace (`sed` alternative) |
| [jq](https://github.com/jqlang/jq) | Command-line JSON processor |
| [yq](https://github.com/mikefarah/yq) | `jq` for YAML |
| [jnv](https://github.com/ynqa/jnv) | Interactive JSON viewer/filter (live `jq`) |

**Git & dev**

| Tool | What it does |
|------|--------------|
| [lazygit](https://github.com/jesseduffield/lazygit) | Full-featured Git TUI |
| [git-delta](https://github.com/dandavison/delta) | Syntax-highlighted git diffs & pager |
| [jj](https://github.com/jj-vcs/jj) | Jujutsu — Git-compatible next-gen VCS |
| [mise](https://github.com/jdx/mise) | Runtime/version manager (Node, Python, …) |
| [tokei](https://github.com/XAMPPRocky/tokei) | Count lines of code by language |
| [hyperfine](https://github.com/sharkdp/hyperfine) | Command-line benchmarking |
| [llmfit](https://github.com/AlexsJones/llmfit) | Find which LLM models fit your hardware (RAM/CPU/GPU) |

**System & monitoring**

| Tool | What it does |
|------|--------------|
| [btop](https://github.com/aristocratos/btop) | Resource monitor (CPU/mem/net/disk) |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | Fast system info (neofetch successor) |
| [procs](https://github.com/dalance/procs) | Modern `ps` replacement |
| [bandwhich](https://github.com/imsnif/bandwhich) | Per-process network usage |
| [dust](https://github.com/bootandy/dust) | Intuitive `du` (disk usage tree) |
| [duf](https://github.com/muesli/duf) | Friendly `df` (disk usage) |
| [dysk](https://github.com/Canop/dysk) | Filesystem usage table (Linux) |

**Multiplexer, HTTP & misc**

| Tool | What it does |
|------|--------------|
| [zellij](https://github.com/zellij-org/zellij) | Terminal multiplexer / workspace |
| [xh](https://github.com/ducaale/xh) | Fast HTTPie-style HTTP client |
| [ouch](https://github.com/ouch-org/ouch) | Compress/decompress any archive format |
| [tlrc](https://github.com/tldr-pages/tlrc) | `tldr` client — simplified, example-driven man pages |
| [topgrade](https://github.com/topgrade-rs/topgrade) | One command to update everything |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Media downloader |
| [parsync](https://github.com/AlpinDale/parsync) | High-throughput parallel file sync over SSH (rsync alternative) |

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
```

### Notes (macOS)

- If sudo is unavailable, Homebrew installs to `~/homebrew` and the setup adds that path automatically.
- macOS app installs (casks/MAS) and networked services are opt-in during install.
- macOS dev profile installs: OrbStack, UTM, Cursor, PHP/Composer/WP-CLI, PHPCS+WPCS, and Cursor settings/extensions seeding.

### Warp terminal (macOS, opt-in)

On GUI-capable macOS machines the installer offers Warp as a standalone choice (prompt, or `--install-warp` / `--skip-warp`). It is independent of the dev profile and is **not** affected by `--skip-casks`. When enabled it:

- installs Warp and the official Cascadia font cask (`font-cascadia-code`, which provides the `Cascadia Code NF` family);
- seeds the **Cobalt2** theme to `~/.warp/themes/Cobalt2.yaml`;
- writes a full starter `~/.warp/settings.toml` from `configs/warp/settings.toml` (font `Cascadia Code NF`, Cobalt2 theme, vertical tabs, `aurora` app icon, block cursor, ligatures, notification prefs, and a secret-redaction regex list) **only if one does not already exist** — Warp rewrites this file at runtime, so an existing config is never clobbered. The `__HOME__` placeholder in the seed is expanded to your `$HOME`.

This snapshots the parts of a "looks cool" Warp setup that Warp's own account sync doesn't reliably bootstrap on a fresh machine (custom theme files + a baseline `settings.toml`). To re-capture after tweaking Warp's appearance, copy your live `~/.warp/settings.toml` back over `configs/warp/settings.toml`, restoring the `__HOME__` placeholder for the theme paths.

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
