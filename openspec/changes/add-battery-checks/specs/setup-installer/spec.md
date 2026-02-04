## ADDED Requirements
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
