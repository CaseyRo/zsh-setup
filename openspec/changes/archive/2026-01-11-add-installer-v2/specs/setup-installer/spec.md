# Setup Installer Specification

## ADDED Requirements

### Requirement: One-Liner Remote Installation

The system SHALL provide a bootstrap script that can be executed via `curl | sh` to install zsh-setup on a fresh machine.

#### Scenario: Fresh installation

- **WHEN** user runs `curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-setup/main/bootstrap.sh | sh`
- **THEN** the repository is cloned to `~/.zsh-setup`
- **AND** the full setup script is executed

#### Scenario: Custom install directory

- **WHEN** user sets ZSH_SETUP_DIR environment variable before running bootstrap
- **THEN** the repository is cloned to the specified directory

#### Scenario: Existing installation

- **WHEN** zsh-setup directory already exists
- **THEN** the system performs a git pull to update
- **AND** runs the setup script

### Requirement: Cargo-First Package Installation

The system SHALL install Rust-based CLI tools via Cargo rather than Homebrew for better cross-platform consistency.

#### Scenario: Cargo packages installed

- **WHEN** the setup script runs
- **THEN** bat, eza, ripgrep, fd-find, zoxide, and topgrade are installed via cargo

#### Scenario: Homebrew packages installed

- **WHEN** the setup script runs
- **THEN** zsh, fzf, byobu, and fastfetch are installed via Homebrew

### Requirement: Sticky Progress Bar

The system SHALL display a progress bar fixed at the bottom of the terminal during installation.

#### Scenario: Progress bar initialization

- **WHEN** the setup script starts installation steps
- **THEN** a progress bar appears at the bottom of the terminal
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
