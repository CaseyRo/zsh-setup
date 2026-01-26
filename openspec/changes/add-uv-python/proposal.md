# Change: Add Python support via uv

## Why

The installer currently sets up Node, Rust, and other tooling but lacks a first-class Python setup. Adding uv provides fast Python installs and environment management with a modern workflow.

## What Changes

- Install uv during setup on supported platforms.
- Install the latest stable Python via uv and set it as the default.
- Report uv/Python status in the installer summary.
- Add an OS-aware PATH hint when uv shims are not detected on PATH.

## Impact

- Affected specs: setup-installer
- Affected code: install/utils.sh, install.sh, install/packages.sh (if needed), install/uv.sh (new)
