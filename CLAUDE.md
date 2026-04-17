# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Cross-platform dotfiles and machine bootstrap for macOS, Ubuntu, and Raspberry Pi (ARM Linux). The repo *is* the deliverable — `~/.zshrc` is symlinked to this repo's `.zshrc`, and `install.sh` is the single entry point for provisioning a machine.

## Commands

```bash
./install.sh                 # Full install (idempotent; re-run is safe)
./install.sh -y              # Non-interactive (answer yes to all)
./install.sh --light         # Minimal server/VPS (no Rust, prefers prebuilt bins)
./install.sh --dev           # macOS dev machine profile (OrbStack, Cursor, PHP/WP-CLI, etc.)
bash scripts/doctor.sh       # Health-check an existing install (alias: `zsh-doctor`)
./run-to-simlink.sh          # Just (re)create the ~/.zshrc symlink

pre-commit run --all-files   # Runs shellcheck (both scopes) + markdownlint + version bump
shellcheck --severity=warning install.sh install/*.sh bootstrap.sh scripts/*.sh
shellcheck --shell=bash --severity=warning $(find modules preload_configs -type f -name '*.sh' ! -name '#*')
bash -n <file>.sh            # Syntax check a single script

docker build -f test/Dockerfile.ubuntu -t zsh-smoke .    # Run install smoke test locally
```

**Two shellcheck scopes, different strictness:**

- **Installer scripts** (`install.sh`, `install/*.sh`, `bootstrap.sh`, `scripts/*.sh`) — bash, strict. Pre-commit runs `--severity=error`; CI runs `--severity=warning`.
- **Runtime shell code** (`modules/**/*.sh`, `preload_configs/**/*.sh`) — bash mode with inline `# shellcheck disable=` for known-good zsh-isms (SC1090 dynamic source, SC2034 on zsh-magic vars like `reply`/`SAVEHIST`, SC2206 on `fpath=(...)`, SC1083 on git `@{upstream}`). Both pre-commit and CI run `--severity=warning`. Keep this clean — when you must disable, scope to a single line with a one-line justification.

`.zshrc` itself is not shellchecked — it has zsh-specific syntax (`fpath+=`, `include` helper, OS-detection branches) that no shellcheck mode handles cleanly.

`VERSION` is auto-bumped by `scripts/bump-version.sh` (pre-commit hook) to `2.0.<commit-count>`. Don't edit it by hand.

## Architecture

### Two-stage config: `install/` vs `modules/`

- **`install/`** — bash scripts for provisioning a machine once (Homebrew, apt, Rust, NVM, uv, Starship, Atuin, dev repos, fonts, etc.). Each file is one installable concern. `install/core.sh` holds arg parsing, module sourcing, and `main()`; `install.sh` itself is a thin entrypoint (root-check → source `core.sh` → call `main`). Package lists live in `install/packages.sh` (`BREW_PACKAGES`, `BREW_PACKAGES_MAC_DEV`, `CARGO_PACKAGES`, `APT_PACKAGES`, `NPM_GLOBAL_PACKAGES`, `DEV_REPOS`, etc.). Add/remove packages there, not in the installer scripts.
- **`modules/`** + **`preload_configs/`** — zsh snippets sourced by `.zshrc` on every shell startup (aliases, functions, completions, tool init). These must stay fast — the shell loads them synchronously.

### Load order (critical)

`.zshrc` walks folders in this strict order, sourcing every `*.sh` in each:

1. `preload_configs/common/path.sh`, then `preload_configs/<os>[/<subos>]/path.sh`
2. `~/.env.sh` (user-private env, gitignored)
3. `preload_configs/common/*.sh` → `preload_configs/<os>/*.sh` → `preload_configs/<os>/<subos>/*.sh` — includes `env.sh` (locale, `PATH` extensions, shared aliases). Runs **before** modules so modules see a settled environment.
4. `modules/common/*.sh` → `modules/<os>/*.sh` → `modules/<os>/<subos>/*.sh`

The loader uses `find ... | sort`, so lexicographic order within a directory matters. The `zz_` prefix is reserved for tail-init modules that *must* load last — currently `modules/common/zz_atuin.sh` (must follow fzf to win Ctrl+R) and `modules/common/zz_zoxide.sh` (must be absolute last; overrides `cd`). Do not add anything that sorts after `zz_zoxide.sh`.

`<os>` is `macos`, `linux`, or `windows`. `<subos>` on Linux is `ubuntu` or `raspberry-pi` — detected from `/etc/os-release` + `uname -m` + the Raspberry Pi devicetree model. If adding new config, place it in the narrowest scope that applies.

### Ignore convention

Any file or folder whose name starts with `#` is skipped by the loader (`find ... ! -name "#*"`). Use `#old_aliases.sh` or `modules/#deprecated/` to disable code without deleting it.

### Platform detection in installers

`install/utils.sh` provides `is_macos`, `is_ubuntu`, `is_debian`, `is_raspberry_pi`, `is_arm`, `is_docker`, `should_use_apt`, `command_exists`. Use these rather than re-checking `$OSTYPE` / `/etc/os-release`. Package-manager preference is **Cargo for Rust tools → Homebrew on macOS → APT on ARM/Linux**, with `install/prebuilt-bins.sh` as a last-resort fallback for `--light` servers where Rust is too heavy to build.

### State & idempotence

- `.install-state` (gitignored) persists user choices between runs (dev machine profile, networked services opt-in). Legacy `.prompt-choice` is auto-migrated.
- Every installer module must be re-runnable — check if the target is already installed and skip, don't error. The installer's value proposition is "safe to re-run."
- Running `install.sh` as root outside Docker triggers an interactive new-user creation flow; inside Docker (`/.dockerenv` or `docker` cgroup) it auto-enables `YES_TO_ALL` and stubs `sudo` as passthrough.

## Conventions

- Deploy = `git add -A && git commit && git push`. This repo has no Vercel/Docker target — pushing to `main` *is* the deploy.
- Installer env-var prefix: `ZSH_SETUP_*`. The old `ZSH_MANAGER_*` aliases have been fully retired — don't re-introduce them.
- `include "$path"` (defined in `.zshrc`) sources a file only if it exists — prefer this over raw `source` in modules so missing optional files don't break shell startup.
- OpenSpec is used for larger changes. Active proposals live in `openspec/changes/`, archived in `openspec/changes/archive/`, specs in `openspec/specs/`. See `openspec/project.md` for project-level context.
