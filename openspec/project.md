# Project Context

## Purpose

ZSH-Setup is a cross-platform ZSH configuration framework that enables users to maintain a single, unified shell configuration across Linux, macOS, and Windows. It provides a modular, portable approach to managing shell settings, aliases, functions, and environment variables.

### Goals

- Provide seamless cross-platform ZSH support (Linux, macOS, Windows/WSL/Git Bash/Cygwin/MSYS2)
- Enable modular organization of shell configurations
- Support automatic OS detection and platform-specific loading
- Allow easy synchronization across devices via Git or cloud services
- Maintain compatibility with popular ZSH frameworks (Oh-My-Zsh, Prezto, Antigen, Zim)

## Tech Stack

- **Shell**: ZSH (Z Shell)
- **Scripting**: Bash/ZSH shell scripts (`.sh` files)
- **Prompt**: Starship cross-shell prompt (TOML configuration)
- **Setup**: Symlink-based installation via Bash script

## Project Conventions

### Code Style

- Shell scripts use `.sh` extension
- Configuration files are organized by OS: `common/`, `linux/`, `macos/`, `windows/`
- Use `#` prefix on filenames/folders to exclude them from loading (e.g., `#deprecated.sh`)
- Environment variables use `ZSH_SETUP_` prefix for framework internals
- Include function wraps file sourcing with existence check

### Architecture Patterns

- **Modular Loading**: Configurations split into `preload_configs/` (loaded first) and `modules/` (loaded after)
- **OS Detection**: Automatic detection via `$OSTYPE` variable with folder-based organization
- **Symlink Setup**: Main `.zshrc` is symlinked from home directory to repository
- **Hierarchical Loading Order**:
  1. OS-specific path configuration (`preload_configs/<os>/path.sh`)
  2. User environment variables (`~/.env.sh`)
  3. Common preload configs, then OS-specific preload configs
  4. Common modules, then OS-specific modules

### Testing Strategy

- Manual testing across target platforms (Linux, macOS, Windows environments)
- Test shell startup time for performance regressions
- Verify OS detection logic for each supported platform

### Git Workflow

- Main branch: `main`
- Sync configurations via Git clone/pull across machines
- Commit message style: Concise, descriptive messages

## Domain Context

- **ZSH**: Z Shell, an extended Bourne shell with many improvements
- **$OSTYPE**: ZSH/Bash variable that identifies the operating system
- **Starship**: A minimal, fast, cross-shell prompt written in Rust
- **Symlink**: Symbolic link allowing `.zshrc` to point to the managed version
- Users may have existing ZSH frameworks (Oh-My-Zsh, etc.) that should work alongside this

## Important Constraints

- Must maintain fast shell startup time (avoid slow operations during loading)
- Must work without root/admin privileges
- Must not break existing ZSH framework installations
- Scripts must handle spaces in file/folder names
- Must gracefully handle missing optional files (use `include` function pattern)

## External Dependencies

- **Starship** (optional): Cross-shell prompt for enhanced prompt styling
- **Git**: For syncing configurations across devices
- **ZSH**: Required shell (not Bash-only compatible)
- Cloud sync services (optional): Dropbox, etc. for non-Git synchronization
