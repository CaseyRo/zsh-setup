## ADDED Requirements

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
