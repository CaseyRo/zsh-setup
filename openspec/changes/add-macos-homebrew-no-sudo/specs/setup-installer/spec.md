## ADDED Requirements
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
