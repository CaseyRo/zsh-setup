# Change: Fix Installer UX Bugs

## Why
Three usability issues affect the installation experience:
1. Bootstrap script fails to detect git when run via `curl | sh` on systems where `sh` is dash (not bash)
2. Screen content overwrites unexpectedly after confirming installation (Y prompt)
3. Cargo package compilation provides no feedback despite taking several minutes

## What Changes
- **Bootstrap script**: Change from `#!/bin/bash` execution assumption to explicit bash invocation, and update the one-liner documentation
- **Progress bar initialization**: Clear screen properly before setting up scroll region to prevent overwrite artifacts
- **Rust/Cargo installation**: Add compilation progress feedback with spinner and informational messages about expected duration

## Impact
- Affected specs: `setup-installer`
- Affected code:
  - `bootstrap.sh` - git detection fix
  - `install/utils.sh` - progress bar initialization
  - `install/rust.sh` - cargo installation feedback
