# Tasks: Enhanced Setup Installer v2.0

## 1. Bootstrap Script
- [x] 1.1 Create bootstrap.sh for remote curl installation
- [x] 1.2 Clone repo to ~/.zsh-manager by default
- [x] 1.3 Support ZSH_MANAGER_DIR environment variable override
- [x] 1.4 Handle existing installations (pull updates)

## 2. Package Management
- [x] 2.1 Move bat, zoxide, eza, ripgrep, fd-find, topgrade to Cargo
- [x] 2.2 Keep zsh, fzf, byobu, fastfetch in Homebrew
- [x] 2.3 Update install/packages.sh with new package lists

## 3. System Info Display
- [x] 3.1 Replace hyfetch with fastfetch in packages
- [x] 3.2 Update startup.sh to prefer fastfetch
- [x] 3.3 Add fallback to hyfetch for existing installations

## 4. Progress Bar
- [x] 4.1 Add progress_init() to set up terminal scroll region
- [x] 4.2 Add progress_draw() to render sticky bottom bar
- [x] 4.3 Add progress_update() to increment and redraw
- [x] 4.4 Add progress_cleanup() to reset terminal state
- [x] 4.5 Integrate progress tracking into install-on-new-machine.sh
- [x] 4.6 Add trap for Ctrl+C to restore terminal

## 5. Documentation
- [x] 5.1 Update README with one-liner install command
- [x] 5.2 Update directory structure documentation
- [x] 5.3 Add changelog for v2.0.0
