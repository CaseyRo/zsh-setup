## ADDED Requirements

### Requirement: Opt-in Warp terminal install

The system SHALL offer Warp as a standalone opt-in install on GUI-capable macOS machines, independent of the dev-machine profile and not gated by `--skip-casks`. The choice SHALL be controllable interactively and via flags, and SHALL persist across runs.

#### Scenario: User opts in interactively

- **WHEN** setup runs on a GUI-capable macOS machine
- **AND** the user is not forcing the choice via a flag
- **AND** the user confirms the Warp prompt
- **THEN** the installer installs Warp and the Cascadia font cask
- **AND** seeds Warp configuration

#### Scenario: User declines

- **WHEN** the user declines the Warp prompt (or passes `--skip-warp`)
- **THEN** the installer installs and configures nothing for Warp

#### Scenario: Forced via flags

- **WHEN** `--install-warp` is passed
- **THEN** Warp is installed without prompting
- **AND** the decision is recorded so subsequent runs reuse it

#### Scenario: Non-interactive default

- **WHEN** setup runs with `--yes` and no explicit Warp flag
- **THEN** Warp is not installed by default

#### Scenario: Non-macOS host

- **WHEN** setup runs on Linux or inside Docker
- **THEN** the Warp install step is a no-op

### Requirement: Warp configuration seeding

When Warp is installed, the system SHALL seed a Cobalt2 theme and a starter settings file without destroying user-managed Warp settings.

#### Scenario: Theme seeded

- **WHEN** the Warp install step runs
- **THEN** the Cobalt2 theme is written to `~/.warp/themes/Cobalt2.yaml`

#### Scenario: Fresh settings seeded

- **WHEN** no `~/.warp/settings.toml` exists
- **THEN** a starter settings file selecting the Cascadia Code NF font and Cobalt2 theme is written

#### Scenario: Existing settings preserved

- **WHEN** `~/.warp/settings.toml` already exists
- **THEN** it is left untouched
- **AND** the user is told how to apply the font and theme manually
