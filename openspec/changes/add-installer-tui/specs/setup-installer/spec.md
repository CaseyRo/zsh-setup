## ADDED Requirements

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
