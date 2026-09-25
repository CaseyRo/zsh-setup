# Change: Add Warp terminal support

## Why

Warp is a common choice on GUI macOS machines, but it has two rough edges this repo can smooth: (1) it isn't installed or configured by the setup, and (2) it uses its own input editor that bypasses zsh's ZLE, so the zsh-abbr Claude Code shortcuts never expand in it. A standalone opt-in keeps non-GUI/server installs lean while giving desktop users a one-shot, consistent Warp setup.

## What Changes

- Add a standalone, opt-in Warp install for GUI-capable macOS machines: an interactive prompt plus `--install-warp` / `--skip-warp` flags, persisted in `.install-state`. Independent of the dev-machine profile and not gated by `--skip-casks`.
- Install Warp and the official Cascadia font cask (`font-cascadia-code`, providing the `Cascadia Code NF` family).
- Seed Warp config: ship the Cobalt2 theme to `~/.warp/themes/`, and write a starter `~/.warp/settings.toml` (font + theme) only when none exists (Warp owns/rewrites that file).
- Add `modules/common/warp.sh` to mirror the zsh-abbr Claude shortcuts as plain aliases under `TERM_PROGRAM=WarpTerminal`, so they work in Warp.

## Impact

- Affected specs: setup-installer, shell-aliases
- Affected code: `install/core.sh`, `install/packages.sh`, `install/warp.sh` (new), `configs/warp/themes/Cobalt2.yaml` (new), `modules/common/warp.sh` (new), `modules/common/zz_abbr.sh`, `README.md`
- Platforms: macOS only; the installer no-ops cleanly on Linux/Docker (CI smoke unaffected).
