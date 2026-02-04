# Change: Make macOS app installation optional

## Why
macOS installs currently add Homebrew casks and Mac App Store apps by default, which can be user-facing or data-usage heavy. Users need a clear opt-in/opt-out path during setup.

## What Changes
- Add prompts and CLI flags to allow skipping macOS app installs (Homebrew casks and Mac App Store apps).
- Default to explicit user confirmation before installing macOS apps.
- Introduce explicit flags for granularity (e.g., `--skip-casks`, `--skip-mas`, `--skip-mac-apps`).
- Surface skipped categories in the install summary.

## Impact
- Affected specs: setup-installer
- Affected code: install.sh, install/brew.sh, install/mas.sh, install/packages.sh
