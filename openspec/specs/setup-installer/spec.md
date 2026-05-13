# setup-installer Specification

## Purpose

Provides automated installation and setup of zsh-setup on new machines, with cross-platform support for macOS, Linux, and Raspberry Pi/ARM.
## Requirements
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

### Requirement: Python Setup via uv

The system SHALL install uv and use it to provision a stable Python version during setup.

#### Scenario: uv installed

- **WHEN** the setup script runs on a supported platform
- **THEN** uv is installed and available on PATH

#### Scenario: Python installed via uv

- **WHEN** uv is available
- **THEN** the latest stable Python is installed via uv
- **AND** the installed Python is set as the default for the user

#### Scenario: uv shims missing on PATH

- **WHEN** uv is installed but its shims directory is not on PATH
- **THEN** the installer prints an OS-aware hint to update PATH

### Requirement: macOS dev machine profile

The system SHALL allow macOS users to enable a dev machine profile during setup, and install additional development tooling only when that profile is enabled.

#### Scenario: User enables dev profile interactively

- **WHEN** setup runs on macOS
- **AND** the user confirms the machine is a dev machine
- **THEN** the installer installs configured dev packages and casks
- **AND** runs dev-only configuration steps

#### Scenario: User disables dev profile interactively

- **WHEN** setup runs on macOS
- **AND** the user declines dev machine mode
- **THEN** dev-only packages and dev-only configuration steps are skipped

#### Scenario: Non-interactive mode defaults dev profile off

- **WHEN** setup runs with `--yes` on macOS
- **AND** no explicit dev profile flag is provided
- **THEN** the dev machine profile remains disabled

#### Scenario: Explicit dev profile flags override prompts

- **WHEN** setup runs on macOS with `--mac-dev-machine` or `--no-mac-dev-machine`
- **THEN** the installer applies the requested mode without prompting

### Requirement: WordPress PHP coding standards setup

The system SHALL install and configure PHPCS with WordPress Coding Standards when the macOS dev machine profile is enabled.

#### Scenario: PHPCS and WPCS are configured

- **WHEN** macOS dev machine setup runs
- **THEN** Composer global packages `squizlabs/php_codesniffer` and `wp-coding-standards/wpcs` are installed
- **AND** PHPCS `installed_paths` includes the WPCS path

### Requirement: Cursor profile seeding for dev machines

The system SHALL seed Cursor user settings and extension list on macOS dev machines.

#### Scenario: Cursor config files are seeded

- **WHEN** macOS dev machine setup runs
- **THEN** Cursor `settings.json` and `keybindings.json` are copied from repository-managed config files

#### Scenario: Cursor CLI missing

- **WHEN** macOS dev machine setup runs
- **AND** the Cursor CLI command is unavailable
- **THEN** extension installation is skipped with a warning

### Requirement: Installer TUI Layout

The system SHALL render a structured TUI layout during installation when stdout is a TTY.

#### Scenario: Status header and progress footer

- **WHEN** the setup script runs in an interactive terminal
- **THEN** a fixed status header displays platform and step count
- **AND** a progress bar remains fixed at the bottom
- **AND** installation output scrolls in the middle region

#### Scenario: Non-interactive output

- **WHEN** the setup script runs without a TTY
- **THEN** TUI layout features are disabled
- **AND** plain log output is emitted without control sequences

### Requirement: Installer Theming and Accessibility

The system SHALL support a consistent color theme and honor `NO_COLOR` for accessibility.

#### Scenario: NO_COLOR disables color output

- **WHEN** `NO_COLOR` is set in the environment
- **THEN** the installer uses plain text without color escape sequences

### Requirement: Optional Rich UI with Gum

The system SHALL support an optional rich TUI mode using `gum` when available, with a safe fallback.

#### Scenario: Gum is available

- **WHEN** the user enables rich UI mode and `gum` is installed
- **THEN** progress and status display use gum components

#### Scenario: Gum is unavailable

- **WHEN** rich UI mode is requested but `gum` is not installed
- **THEN** the installer falls back to the standard TUI layout
- **AND** continues without error

### Requirement: Sticky Current-Step Status

The system SHALL display the current step status in a fixed position during installation.

#### Scenario: Step status updates

- **WHEN** the installer advances to a new step
- **THEN** the sticky current-step line updates to the new step label

### Requirement: Completion Summary

The system SHALL display an end-of-run summary with counts and elapsed time.

#### Scenario: Summary after completion

- **WHEN** installation completes
- **THEN** the installer prints counts of installed, skipped, and failed items
- **AND** the elapsed time is shown

### Requirement: macOS networked services opt-in

The system SHALL require explicit opt-in before installing macOS networked services that may expose data or network access, while still installing Copyparty by default.

#### Scenario: User declines macOS networked services

- **WHEN** setup runs on macOS
- **AND** the user declines networked services
- **THEN** Tailscale and Node-RED are skipped
- **AND** Copyparty is still installed
- **AND** the summary reports the skipped services

#### Scenario: User opts in to macOS networked services

- **WHEN** setup runs on macOS
- **AND** the user opts in to networked services
- **THEN** Tailscale and Node-RED are installed as configured
- **AND** Copyparty is installed

#### Scenario: Non-interactive skip via flag

- **WHEN** setup runs with a skip flag for macOS networked services
- **THEN** Tailscale and Node-RED are skipped without prompting
- **AND** Copyparty is still installed

### Requirement: macOS user-space Homebrew fallback

The system SHALL install Homebrew in a user-writable directory on macOS when sudo is unavailable, without blocking the rest of setup.

#### Scenario: macOS user without sudo installs Homebrew

- **WHEN** setup runs on macOS
- **AND** sudo is unavailable for the current user
- **THEN** Homebrew is installed under a user-writable directory (e.g., `~/homebrew`)
- **AND** the current session PATH is updated to include the user-space Homebrew bin
- **AND** the installer continues without requiring sudo

#### Scenario: macOS user with sudo installs Homebrew

- **WHEN** setup runs on macOS
- **AND** sudo is available for the current user
- **THEN** Homebrew is installed using the default installer flow

#### Scenario: Non-macOS platforms

- **WHEN** setup runs on a non-macOS platform
- **THEN** the Homebrew install behavior is unchanged

### Requirement: Battery level safety checks

The system SHALL detect battery level when a battery is present and enforce warning/abort thresholds to prevent failed installs.

#### Scenario: Battery below warning threshold

- **WHEN** setup runs on a device with a battery
- **AND** battery level is below 50%
- **THEN** the installer shows a warning before continuing

#### Scenario: Battery below abort threshold

- **WHEN** setup runs on a device with a battery
- **AND** battery level is below 25%
- **THEN** the installer aborts before making changes

#### Scenario: No battery present

- **WHEN** setup runs on a device without a battery
- **THEN** no battery warning or abort is triggered

#### Scenario: Abort override

- **WHEN** setup runs with an explicit override flag for low battery
- **THEN** the installer continues even if battery is below 25%

### Requirement: Optional macOS app installation

The system SHALL allow users to opt in or opt out of installing macOS GUI apps during setup.

#### Scenario: User declines macOS app installation

- **WHEN** setup runs on macOS
- **AND** the user declines installing macOS apps
- **THEN** Homebrew casks and Mac App Store apps are skipped
- **AND** the summary reports the skipped categories

#### Scenario: User opts in to macOS app installation

- **WHEN** setup runs on macOS
- **AND** the user opts in to install macOS apps
- **THEN** Homebrew casks and Mac App Store apps are installed as configured

#### Scenario: Non-interactive skip via flag

- **WHEN** setup runs with a skip flag for macOS apps (e.g., `--skip-mac-apps`, `--skip-casks`, or `--skip-mas`)
- **THEN** Homebrew casks and Mac App Store apps are skipped without prompting

