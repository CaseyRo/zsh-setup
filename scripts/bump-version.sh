#!/usr/bin/env bash
# Auto-set version based on commit count
# Called by pre-commit hook
# Format: 2.0.<total-commit-count>

VERSION_FILE="$(git rev-parse --show-toplevel)/VERSION"

# Current commit count + 1 (this commit hasn't been created yet)
COMMIT_COUNT=$(($(git rev-list --count HEAD) + 1))

echo "2.0.${COMMIT_COUNT}" > "$VERSION_FILE"

git add "$VERSION_FILE"
