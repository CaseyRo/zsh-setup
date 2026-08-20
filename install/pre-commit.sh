#!/bin/bash
# ============================================================================
# ZSH-Setup: pre-commit gate
# ============================================================================
# Installs the pre-commit binary and, more importantly, the git hook itself.
# The binary alone is not the gate. Without .git/hooks/pre-commit a commit runs
# no checks at all: both shellcheck scopes are skipped, markdownlint is skipped,
# and VERSION quietly stops tracking the commit count with nothing to report it.
# This repository's own primary machine drifted sixteen commits that way before
# anyone noticed, so the hook is treated as the deliverable and the binary as a
# prerequisite.
#
# The route is deliberately not apt. This repo's .pre-commit-config.yaml uses
# `stages: [pre-commit]`, a spelling only understood from pre-commit 3.2.0
# onward, and the apt package is older than that on both Linux targets: Ubuntu
# 22.04 ships 2.17.0 and Raspberry Pi OS bookworm ships 3.0.4. Either installs
# cleanly and then fails to parse this repo's config, which is an
# installed-but-dead gate rather than a working one. macOS takes the Homebrew
# formula through BREW_PACKAGES_MAC_DEV; every other platform goes through uv,
# the same route install/copyparty.sh uses for Python command line tools.
#
# Gated on the dev profile for the same reason shellcheck is: the hooks shell
# out to shellcheck, which only dev machines install. Installing the hook on a
# machine without it would make every commit fail instead of every commit pass.
# ============================================================================

# Lowest version whose `stages:` grammar this repo's config relies on.
PRE_COMMIT_MIN_VERSION="3.2.0"

# True when version $1 is at least $2. sort -V so 3.10 correctly beats 3.2.
_pre_commit_version_at_least() {
    [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

_pre_commit_installed_version() {
    pre-commit --version 2>/dev/null | awk '{print $2}'
}

install_pre_commit() {
    # Dev profile only. IS_MAC_DEV_MACHINE is the repo-wide `--dev` switch
    # despite the name, matching install_apt_packages_dev.
    if [[ "${IS_MAC_DEV_MACHINE:-false}" != true ]]; then
        return 0
    fi

    local repo_root="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

    if [[ ! -d "$repo_root/.git" ]]; then
        return 0
    fi

    print_section "pre-commit (repo gates)"

    # 1. Binary. macOS already has it from BREW_PACKAGES_MAC_DEV by this point.
    if ! command_exists pre-commit; then
        if ! command_exists uv; then
            print_warning "Neither pre-commit nor uv available; repo gates will not run locally"
            track_failed "pre-commit"
            return 0
        fi
        if ! run_with_spinner "Installing pre-commit" uv tool install pre-commit; then
            print_warning "pre-commit install failed; repo gates will not run locally"
            track_failed "pre-commit"
            return 0
        fi
    fi

    # 2. Version. Presence is not health: an older binary installs fine and then
    #    cannot parse this repo's config, so the gate looks present and is not.
    local version
    version=$(_pre_commit_installed_version)
    if [[ -n "$version" ]] && ! _pre_commit_version_at_least "$version" "$PRE_COMMIT_MIN_VERSION"; then
        print_warning "pre-commit $version predates $PRE_COMMIT_MIN_VERSION and cannot parse this repo's config"
        print_info "Upgrade with: uv tool install --force pre-commit"
        track_failed "pre-commit"
        return 0
    fi

    # 3. The hook, which is the part that actually gates a commit.
    if [[ -f "$repo_root/.git/hooks/pre-commit" ]]; then
        print_skip "pre-commit hook"
        track_skipped "pre-commit hook"
        return 0
    fi

    if run_with_spinner "Installing pre-commit hook" bash -c "cd \"$repo_root\" && pre-commit install"; then
        print_success "pre-commit hook installed"
        track_installed "pre-commit hook"
    else
        print_warning "pre-commit install failed; commits will not run repo gates"
        track_failed "pre-commit hook"
    fi

    return 0
}
