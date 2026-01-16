# Change: Add installer TUI polish and optional gum UI

## Why
The current installer output is functional but visually basic. A more structured, modern TUI improves usability and perceived quality without changing installation behavior.

## What Changes
- Add a structured TUI layout with a top status bar and bottom progress bar.
- Introduce theming with consistent palettes, `NO_COLOR` support, and TTY detection.
- Add an optional rich mode powered by `gum` with graceful fallback.
- Add a sticky "now" status line and last-error indicator for quick feedback.
- Add a completion summary line with counts and elapsed time.

## Impact
- Affected specs: setup-installer
- Affected code: install/utils.sh, install.sh (progress/status rendering)
