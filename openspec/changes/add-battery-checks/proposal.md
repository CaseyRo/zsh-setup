# Change: Add battery level checks for installs

## Why
Long-running installs on laptops can fail if battery is low. Providing a warning and abort threshold helps prevent mid-install shutdowns and data loss.

## What Changes
- Detect battery level when a battery is present.
- Warn the user if battery level is below 50%.
- Abort installation if battery level is below 25% unless explicitly overridden.

## Impact
- Affected specs: setup-installer
- Affected code: install.sh, install/utils.sh (battery detection utilities)
