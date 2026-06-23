## ADDED Requirements

### Requirement: Claude shortcuts in Warp

Because Warp bypasses zsh's ZLE, the zsh-abbr Claude Code shortcuts do not expand in it. The system SHALL provide the same shortcuts as plain aliases when running in Warp, so they work there too.

#### Scenario: Running in Warp

- **WHEN** the shell starts with `TERM_PROGRAM` set to `WarpTerminal`
- **AND** `claude` is available on PATH
- **THEN** `cl`, `clc`, `clr`, `cla`, `clac`, `clar`, `clp`, `cly`, `clyc`, `clmax`, and `clweb` are defined as aliases to the matching `claude` invocations

#### Scenario: Running in a non-Warp terminal

- **WHEN** the shell starts outside Warp
- **THEN** the Warp aliases are not defined
- **AND** the existing zsh-abbr abbreviations remain the active mechanism
