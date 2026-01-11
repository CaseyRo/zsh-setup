# Change: Enhanced Setup Installer v2.0

## Why
The original setup process required manual cloning and running multiple scripts. Users wanted a streamlined one-liner installation experience with visual feedback during the lengthy setup process.

## What Changes
- Add bootstrap script for one-liner remote installation (`curl ... | sh`)
- Add sticky progress bar that stays at bottom of terminal during setup
- Switch core CLI tools from Homebrew to Cargo for better cross-platform consistency
- Replace hyfetch with fastfetch for significantly faster shell startup
- Add proper terminal cleanup on interrupt (Ctrl+C)

## Impact
- Affected specs: setup-installer (new capability)
- Affected code:
  - `bootstrap.sh` (new)
  - `install-on-new-machine.sh` (modified)
  - `install/utils.sh` (modified - progress bar)
  - `install/packages.sh` (modified - cargo-first)
  - `modules/common/startup.sh` (modified - fastfetch)
  - `README.md` (updated documentation)
