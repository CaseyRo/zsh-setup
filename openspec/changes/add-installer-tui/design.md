## Context

The installer currently provides a spinner and a sticky progress bar, but lacks a structured layout and consistent theming. Users requested a more modern TUI-like experience.

## Goals / Non-Goals

- Goals: Provide a clear status header, sticky current-step line, consistent palette, and optional gum-based rich UI.
- Non-Goals: Changing install behavior, adding new install steps, or requiring network access.

## Decisions

- Decision: Add a top status bar and bottom progress bar using ANSI control sequences with TTY detection.
- Decision: Introduce a theming layer with `NO_COLOR` support and a minimal default theme.
- Decision: Support optional `gum` usage only when installed or explicitly enabled; otherwise fallback to the current style.

## Risks / Trade-offs

- Risk: Control sequences may misbehave in non-TTY output.
  - Mitigation: Detect `-t 1` and disable layout features for non-interactive environments.
- Risk: Additional UI logic increases complexity.
  - Mitigation: Centralize UI rendering in `install/utils.sh`.

## Migration Plan

- No migration required; changes are backward compatible.

## Open Questions

- None.
