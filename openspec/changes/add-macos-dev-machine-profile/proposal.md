# Change: Add macOS dev machine profile

## Why

macOS setups vary between general-use and development-focused machines. A dedicated dev profile keeps standard installs lean while enabling a richer toolchain when needed.

## What Changes

- Add a macOS prompt and CLI flags to enable/disable a dev machine profile.
- Add dev-only package/cask lists for OrbStack, UTM, Cursor, PHP, Composer, and WP-CLI.
- Add PHPCS + WordPress Coding Standards setup via Composer global install and PHPCS path configuration.
- Seed Cursor settings/keybindings and install a curated extension set on macOS dev machines.

## Impact

- Affected specs: setup-installer
- Affected code: `install.sh`, `install/packages.sh`, `install/brew.sh`, `install/php-dev.sh`, `install/cursor.sh`, `configs/cursor/*`, `README.md`
