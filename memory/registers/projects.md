# Projects Register

> Load when a project is discussed.
> Contains project state, goals, key decisions, and blockers.

---

## zsh-setup

- **claim**: Cross-platform dotfiles and machine bootstrap for macOS, Ubuntu (x86_64), and Raspberry Pi (ARM). ^tr4a1b2c3d4e
- **confidence**: high
- **evidence**: CLAUDE.md + install.sh + packages.sh reviewed 2026-02-19
- **last_verified**: 2026-02-19

### Purpose

Automated setup of a consistent shell environment across machines. Run `./install.sh` on a new machine to get everything configured.

### Entry Points

- `install.sh` — main installer (never run as root; prompts for sudo internally)
- `bootstrap.sh` — quick start for new machines
- `run-to-simlink.sh` — symlinks `.zshrc` to `~/`

### Directory Structure

```
install/          # Installer modules (brew, apt, rust, nvm, mas, etc.)
install/packages.sh  # ALL package lists — single source of truth
modules/          # Zsh config modules sourced by .zshrc
  common/         # Loaded on all platforms (aliases, functions, tools, etc.)
  linux/raspberry-pi/
  linux/ubuntu/
  macos/
  windows/        # Stub (gitkeep only)
preload_configs/  # Platform PATH and init scripts (loaded before modules)
  common/
  linux/raspberry-pi/
  linux/ubuntu/
  macos/
configs/          # App configs (e.g. topgrade.toml)
scripts/          # Utility scripts (e.g. copyparty-server.sh)
openspec/         # AI spec-driven development proposals
```

### Key Module Files (modules/common/)

- `aliases.sh` — shell aliases
- `functions.sh` — shell functions
- `tools.sh` — tool initialization (zoxide, fzf, etc.)
- `completions.sh` — tab completion setup
- `oh-my-zsh.sh` — OMZ config
- `auto-update.sh` — update checker
- `startup.sh` — startup tasks
- `autosuggestions.sh` — fish-style suggestions
- `autocomplete.sh` — autocomplete config
- `tailscale.sh` — Tailscale integration
- `copyparty.sh` — Copyparty file server integration

### Install Modules (install/)

- `brew.sh`, `apt.sh`, `rust.sh`, `nvm.sh`, `oh-my-zsh.sh`
- `mas.sh` — Mac App Store apps
- `nerd-fonts.sh` — Nerd Font installation
- `network-mounts.sh` — NFS mount setup
- `tailscale.sh`, `copyparty.sh`, `lazygit.sh`, `uv.sh`
- `splash.sh` — startup splash screen
- `upgrade.sh` — system upgrade routines
- `utils.sh` — shared installer utilities
- `git-confirmer.sh` — git safety tool

### State

- **Status**: Active / maintained
- **Blockers**: None known
