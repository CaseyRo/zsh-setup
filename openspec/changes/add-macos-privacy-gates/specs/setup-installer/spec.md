## ADDED Requirements
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
