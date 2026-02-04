# Change: Support non-sudo Homebrew install on macOS

## Why
macOS users without sudo access cannot run the standard Homebrew installer, which blocks setup entirely. Provide a non-blocking check and a user-space Homebrew fallback so the installer can proceed without admin privileges when needed.

## What Changes
- Add a non-blocking sudo availability check on macOS.
- When sudo is unavailable, install Homebrew into a user-writable directory (e.g., `~/homebrew`) instead of system locations.
- Ensure PATH setup for the user-space Homebrew install is applied for the current session and documented for persistence.
- Preserve the default Homebrew install flow when sudo is available.

## Impact
- Affected specs: setup-installer
- Affected code: install/brew.sh, install.sh, install/utils.sh
