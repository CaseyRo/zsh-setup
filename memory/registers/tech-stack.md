# Tech Stack Register

> Load when technical choices, tools, or languages come up.
> Contains languages, frameworks, tools, and constraints in use.

---

## zsh-setup Project

- **claim**: Platform targets: macOS (Homebrew-primary), Ubuntu x86_64 (APT-primary), Raspberry Pi ARM (APT-primary). ^tr9f8e7d6c5b
- **confidence**: high
- **evidence**: install.sh + packages.sh reviewed 2026-02-19
- **last_verified**: 2026-02-19

### Package Manager Strategy

| Platform | Primary | Secondary (Rust tools) | Notes |
|----------|---------|----------------------|-------|
| macOS | Homebrew | Cargo | MAS for GUI apps |
| Ubuntu x86_64 | APT | Cargo (what's not in APT) | npm globals too |
| Raspberry Pi | APT | Cargo (what's not in APT) | No desktop/GUI apps |

**Rule**: Prefer Cargo for Rust-native CLI tools. Use Homebrew/APT for everything else. Only use Cargo on APT systems when the tool isn't in apt.

### Tools Installed (all platforms)

- **Shell**: zsh + Oh My Zsh
- **Version manager**: nvm (Node)
- **Prompt**: Powerlevel10k (via OMZ)
- **Fonts**: Nerd Fonts — FiraMono, JetBrainsMono, Meslo (desktop only)
- **Core CLI**: git, gh (GitHub CLI), fzf, byobu, fastfetch, btop
- **Rust tools** (via Cargo): bat, zoxide, eza, ripgrep (rg), fd-find, topgrade, cargo-cache
- **APT extras**: micro (text editor), unzip, nfs-common, figlet, cmatrix, toilet
- **npm globals**: pm2, @fission-ai/openspec, node-red (networked/opt-in), nori-ai-cli (desktop)
- **macOS extras**: 1password-cli, raycast (cask), setapp (cask), MAS apps

### macOS MAS Apps

- 1Password for Safari (1569813296)
- AutoMounter (1160435653)
- iHosts (1102004240)
- Things (904280696)
- TrashMe 3 (1490879410)

### Platform Detection Pattern

Installer checks `uname` / `EUID` / arch. Platform-specific branches run in `install.sh` and modules are sourced conditionally in `.zshrc`.

### Security Constraint

Never run `install.sh` as root. Script uses `sudo` internally only for operations that need it (apt, system dirs). Running as root breaks user-level file ownership.

### Spec / AI Tooling

- OpenSpec (`@fission-ai/openspec`) for spec-driven AI development proposals
- Specs live in `openspec/` — see `openspec/AGENTS.md` for proposal workflow

<!-- Add further entries as technical decisions are made -->
