## 1. Implementation

- [x] 1.1 Add `--install-warp` / `--skip-warp` flags, help text, and `INSTALL_WARP` / `WARP_EXPLICIT` state to the installer.
- [x] 1.2 Add a standalone Warp opt-in prompt on GUI-capable macOS machines, persisted to/read from `.install-state` (`WARP=`).
- [x] 1.3 Add `install/warp.sh`: install Warp + Cascadia font cask, seed the Cobalt2 theme, and seed `settings.toml` only when absent. Source it and call `install_warp` in the macOS flow.
- [x] 1.4 Add the Cobalt2 theme asset under `configs/warp/themes/`.
- [x] 1.5 Add `modules/common/warp.sh` mirroring the zsh-abbr Claude shortcuts as aliases under `TERM_PROGRAM=WarpTerminal`; cross-reference from `zz_abbr.sh`.
- [x] 1.6 Update README (options + macOS Warp section).
