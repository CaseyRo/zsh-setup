# shell-aliases Specification

## Purpose

TBD - created by archiving change add-git-confirmer-alias. Update Purpose after archive.

## Requirements

### Requirement: git_confirmer aliases

The system SHALL provide `gc` and `gcs` aliases for `git_confirmer` when the command is available.

#### Scenario: git_confirmer installed

- **WHEN** `git_confirmer` is available on PATH
- **THEN** the `gc` alias invokes `git_confirmer`
- **AND** the `gcs` alias invokes `git_confirmer --ship`

#### Scenario: git_confirmer missing

- **WHEN** `git_confirmer` is not available on PATH
- **THEN** no `gc` or `gcs` alias is defined

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
