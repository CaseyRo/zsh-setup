# Change: Add macOS privacy gates for networked services

## Why
Some macOS setup steps install networked services that could affect data sharing or network exposure. Users should explicitly opt in to these services while ensuring critical tooling like Copyparty remains installed.

## What Changes
- Add an explicit opt-in gate for macOS networked services (e.g., Tailscale, Node-RED).
- Keep Copyparty installation enabled regardless of the privacy gate.
- Summarize which networked services were skipped.

## Impact
- Affected specs: setup-installer
- Affected code: install.sh, install/tailscale.sh, install/packages.sh
