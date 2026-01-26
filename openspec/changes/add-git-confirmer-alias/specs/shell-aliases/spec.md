## ADDED Requirements

### Requirement: git_confirmer aliases

The system SHALL provide `gc` and `gcs` aliases for `git_confirmer` when the command is available.

#### Scenario: git_confirmer installed

- **WHEN** `git_confirmer` is available on PATH
- **THEN** the `gc` alias invokes `git_confirmer`
- **AND** the `gcs` alias invokes `git_confirmer --ship`

#### Scenario: git_confirmer missing

- **WHEN** `git_confirmer` is not available on PATH
- **THEN** no `gc` or `gcs` alias is defined
