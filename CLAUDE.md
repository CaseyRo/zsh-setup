## zsh-setup

Cross-platform dotfiles and machine bootstrap for macOS, Ubuntu, and Raspberry Pi.

### Structure

- `install.sh` - Main installer entry point
- `install/` - Installer modules (brew, apt, rust, nvm, etc.)
- `install/packages.sh` - Package lists (BREW_PACKAGES, CARGO_PACKAGES, APT_PACKAGES, NPM_GLOBAL_PACKAGES, etc.)
- `modules/` - Zsh config modules loaded by .zshrc (aliases, functions, tools, completions)
- `preload_configs/` - Platform-specific PATH and init scripts
- `bootstrap.sh` - Quick bootstrap for new machines
- `.zshrc` - Main zsh config (symlinked to ~/)

### Key Patterns

- Platform detection: macOS vs Linux (Ubuntu vs Raspberry Pi)
- Package preference: Cargo for Rust tools, Homebrew for the rest, APT on ARM
- Modular zsh config with platform-specific overrides

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->