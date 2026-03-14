#!/usr/bin/env bash
# Auto-bump patch version on every commit
# Called by pre-commit hook

VERSION_FILE="$(git rev-parse --show-toplevel)/VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "0.1.0" > "$VERSION_FILE"
fi

VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
PATCH=$((PATCH + 1))
echo "${MAJOR}.${MINOR}.${PATCH}" > "$VERSION_FILE"

git add "$VERSION_FILE"
