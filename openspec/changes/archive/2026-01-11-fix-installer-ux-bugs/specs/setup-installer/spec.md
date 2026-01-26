## MODIFIED Requirements

### Requirement: One-Liner Remote Installation

The system SHALL provide a bootstrap script that can be executed via `bash -c "$(curl ...)"` to install zsh-setup on a fresh machine.

#### Scenario: Fresh installation

- **WHEN** user runs `bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-setup/main/bootstrap.sh)"`
- **THEN** the repository is cloned to `~/.zsh-setup`
- **AND** the full setup script is executed

#### Scenario: Custom install directory

- **WHEN** user sets ZSH_SETUP_DIR environment variable before running bootstrap
- **THEN** the repository is cloned to the specified directory

#### Scenario: Existing installation

- **WHEN** zsh-setup directory already exists
- **THEN** the system performs a git pull to update
- **AND** runs the setup script

#### Scenario: Git detection on dash-based systems

- **WHEN** bootstrap runs on a system where /bin/sh is dash (Debian/Ubuntu)
- **THEN** git is correctly detected if installed
- **AND** a helpful error message is shown if git is not installed

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
