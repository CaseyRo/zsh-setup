# Change: Add git_confirmer alias

## Why

Users want a short alias for the git_confirmer tool across supported platforms with Rust installed.

## What Changes

- Add a `gc` alias for `git_confirmer` when the command is available.
- Add a `gcs` alias for `git_confirmer --ship` when the command is available.
- Keep behavior consistent across platforms that have Rust tooling installed.

## Impact

- Affected specs: shell-aliases
- Affected code: modules/common/aliases.sh
