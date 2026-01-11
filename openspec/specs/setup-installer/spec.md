# setup-installer Specification

## Purpose
Provides automated installation and setup of zsh-manager on new machines, with cross-platform support for macOS, Linux, and Raspberry Pi/ARM.

## Requirements

### Requirement: One-Liner Remote Installation
The system SHALL provide a bootstrap script that can be executed via `bash -c "$(curl ...)"` to install zsh-manager on a fresh machine.

#### Scenario: Fresh installation
- **WHEN** user runs `bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-manager/main/bootstrap.sh)"`
- **THEN** the repository is cloned to `~/.zsh-manager`
- **AND** the full setup script is executed

#### Scenario: Custom install directory
- **WHEN** user sets ZSH_MANAGER_DIR environment variable before running bootstrap
- **THEN** the repository is cloned to the specified directory

#### Scenario: Existing installation
- **WHEN** zsh-manager directory already exists
- **THEN** the system performs a git pull to update
- **AND** runs the setup script

#### Scenario: Git detection on dash-based systems
- **WHEN** bootstrap runs on a system where /bin/sh is dash (Debian/Ubuntu)
- **THEN** git is correctly detected if installed
- **AND** a helpful error message is shown if git is not installed

### Requirement: Cargo-First Package Installation
The system SHALL install Rust-based CLI tools via Cargo with clear progress feedback.

#### Scenario: Cargo packages installed
- **WHEN** the setup script runs
- **THEN** bat, eza, ripgrep, fd-find, zoxide, and topgrade are installed via cargo

#### Scenario: Homebrew packages installed
- **WHEN** the setup script runs
- **THEN** zsh, fzf, byobu, btop, and fastfetch are installed via Homebrew

#### Scenario: Compilation progress feedback
- **WHEN** cargo packages are being compiled
- **THEN** an informational message is displayed about expected compilation time
- **AND** actual cargo compilation output is visible to the user
- **AND** package progress is shown (e.g., "Package 2 of 6")

### Requirement: Sticky Progress Bar
The system SHALL display a progress bar fixed at the bottom of the terminal during installation with proper screen management.

#### Scenario: Progress bar initialization
- **WHEN** the setup script starts installation steps
- **THEN** the screen is cleared
- **AND** a progress bar appears at the bottom of the terminal
- **AND** installation output scrolls above the progress bar

#### Scenario: Progress updates
- **WHEN** each installation step completes
- **THEN** the progress bar updates to reflect completion percentage
- **AND** displays the name of the completed step

#### Scenario: Terminal interrupt handling
- **WHEN** user presses Ctrl+C during installation
- **THEN** the terminal scroll region is reset to normal
- **AND** the cursor is restored

### Requirement: Fast System Info Display
The system SHALL use fastfetch for displaying system information on shell startup.

#### Scenario: Fastfetch available
- **WHEN** a new shell session starts
- **AND** fastfetch is installed
- **THEN** fastfetch displays system information

#### Scenario: Fallback to hyfetch
- **WHEN** a new shell session starts
- **AND** fastfetch is not installed
- **AND** hyfetch is installed
- **THEN** hyfetch displays system information

### Requirement: Auto-Upgrade on Update
The system SHALL automatically install new packages added to the configuration after a git pull.

#### Scenario: New package in config
- **WHEN** a git pull brings in new packages in packages.sh
- **THEN** the upgrade script detects missing packages
- **AND** installs them automatically

#### Scenario: Manual update command
- **WHEN** user runs `zsh-update`
- **THEN** git pull is performed
- **AND** any new packages are installed
- **AND** shell config is reloaded
