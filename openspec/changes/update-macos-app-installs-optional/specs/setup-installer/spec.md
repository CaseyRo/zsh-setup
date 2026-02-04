## ADDED Requirements
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
