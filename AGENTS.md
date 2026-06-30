# AGENTS.md

Agent instructions for this repo (read by Warp Agent Mode, Codex, and other
`AGENTS.md`-aware tools). **The canonical, fuller guidance lives in
[`CLAUDE.md`](./CLAUDE.md) — read it first.** This file mirrors only the rules
most likely to bite an agent that acts without reading it.

## What this repo is

Cross-platform zsh dotfiles + machine bootstrap (macOS, Ubuntu, Raspberry Pi).
The repo *is* the deliverable: `~/.zshrc` is symlinked to `.zshrc`, and
`install.sh` is the single, idempotent provisioning entry point.

## Load-bearing rules

- **Idempotence is the contract.** Every `install/*.sh` module must be safe to
  re-run — check if a target exists and skip, never error.
- **Two shellcheck scopes.** Installer scripts (`install.sh`, `install/*.sh`,
  `bootstrap.sh`, `scripts/*.sh`) are strict bash. Runtime shell code
  (`modules/**`, `preload_configs/**`) is bash-mode with inline
  `# shellcheck disable=` for known zsh-isms. Keep both clean.
- **Package lists live in `install/packages.sh`**, not in installer modules.
- **Load order matters** — `.zshrc` sources `preload_configs/` then `modules/`
  in lexicographic order. `zz_`-prefixed modules load last; nothing may sort
  after `modules/common/zz_zoxide.sh`. Files/dirs starting with `#` are skipped.
- **`VERSION` is auto-bumped** by `scripts/bump-version.sh` (pre-commit) — never
  edit it by hand.
- **Env-var prefix is `ZSH_SETUP_*`.** The old `ZSH_MANAGER_*` aliases are
  retired — don't reintroduce them.
- **Deploy = commit + push to `main`.** There is no other deploy target.

## Before committing

```bash
pre-commit run --all-files     # shellcheck (both scopes) + markdownlint + version bump
```
