## ADDED Requirements

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
