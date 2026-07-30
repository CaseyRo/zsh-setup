#!/bin/bash
# ============================================================================
# mise (version manager) Installation
# ============================================================================
# mise (https://mise.jdx.dev) is a fast, Rust-based asdf/nvm replacement that
# manages Node (and other runtimes) with per-directory auto-switching and a
# near-zero shell-startup cost. It supersedes NVM in this setup:
#
#   - The old per-OS nvm runtime modules have been removed.
#   - modules/common/mise.sh activates mise on every shell.
#   - install/nvm.sh now only provides install_npm_global_packages().
#
# Idempotent: re-running skips an already-installed mise and an already-pinned
# global Node.
# ============================================================================

# Resolve a usable mise binary path (brew puts it on PATH; the curl installer
# drops it at ~/.local/bin/mise which may not be on the installer's PATH yet).
_mise_bin() {
    if command_exists mise; then
        echo "mise"
    elif [[ -x "$HOME/.local/bin/mise" ]]; then
        echo "$HOME/.local/bin/mise"
    else
        return 1
    fi
}

# True only if a mise binary exists AND actually executes. An executable-but-
# broken binary (e.g. glibc build on a too-old libc) must not count as
# installed, or the skip guard would keep a dead mise forever.
_mise_works() {
    { command_exists mise && mise --version; } &>/dev/null && return 0
    [[ -x "$HOME/.local/bin/mise" ]] && "$HOME/.local/bin/mise" --version &>/dev/null
}

# The official installer picks the glibc build, which needs GLIBC >= 2.38 —
# newer than Debian 12 / Raspberry Pi OS bookworm ships (2.36). The musl build
# is static and runs on any libc; runtimes mise manages (node etc.) pick their
# own libc and are unaffected.
_mise_install_musl() {
    local arch
    case "$(uname -m)" in
        aarch64 | arm64) arch="arm64" ;;
        x86_64) arch="x64" ;;
        *) return 1 ;;
    esac
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "https://mise.jdx.dev/mise-latest-linux-${arch}-musl" -o "$HOME/.local/bin/mise" \
        && chmod +x "$HOME/.local/bin/mise"
}

install_mise() {
    print_section "mise (version manager)"

    if _mise_works; then
        print_skip "mise"
        track_skipped "mise"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
        print_package "mise"
        if run_with_spinner "Installing mise" brew install mise; then
            print_success "mise installed"
            track_installed "mise"
        else
            print_error "Failed to install mise"
            track_failed "mise"
            return 1
        fi
    else
        print_step "Installing mise"
        if [[ "$VERBOSE" == true ]]; then
            curl -fsSL https://mise.run | sh
        else
            curl -fsSL https://mise.run 2>/dev/null | sh &>/dev/null
        fi

        # Glibc-too-old (bookworm) leaves a binary that exists but can't run.
        if ! _mise_works; then
            print_step "mise glibc build doesn't run on this libc — installing musl build"
            _mise_install_musl
        fi

        if _mise_works; then
            print_success "mise installed"
            track_installed "mise"
        else
            print_error "mise installation failed"
            track_failed "mise"
            return 1
        fi
    fi
}

mise_install_node() {
    print_section "Node.js (via mise)"

    local mise
    if ! mise="$(_mise_bin)"; then
        print_error "mise not available, skipping Node.js installation"
        track_failed "Node.js (mise not available)"
        return 1
    fi

    # Make sure the curl-installed mise binary is reachable for this session.
    export PATH="$HOME/.local/bin:$PATH"

    if "$mise" which node &>/dev/null; then
        print_skip "Node.js ($("$mise" exec -- node --version 2>/dev/null))"
        track_skipped "Node.js (mise)"
    else
        print_step "Installing Node.js LTS via mise"
        if [[ "$VERBOSE" == true ]]; then
            "$mise" use -g node@lts
        else
            "$mise" use -g node@lts &>/dev/null
        fi

        if "$mise" which node &>/dev/null; then
            print_success "Node.js $("$mise" exec -- node --version 2>/dev/null) installed"
            track_installed "Node.js (mise)"
        else
            print_error "Node.js installation via mise failed"
            track_failed "Node.js (mise)"
            return 1
        fi
    fi

    # Expose node/npm shims to the rest of the installer (install_npm_global_packages).
    "$mise" reshim &>/dev/null || true
    export PATH="$HOME/.local/share/mise/shims:$PATH"
}

# Pin the MISE_TOOLS list globally. Separate from mise_install_node because
# nothing later in the installer depends on these being on PATH mid-run.
mise_install_tools() {
    if [[ ${#MISE_TOOLS[@]} -eq 0 ]]; then
        return 0
    fi

    local mise
    if ! mise="$(_mise_bin)"; then
        print_warning "mise not installed, skipping mise tools"
        return 0
    fi

    print_section "mise Tools"

    local tool name
    for tool in "${MISE_TOOLS[@]}"; do
        name="${tool%%@*}"

        if "$mise" which "$name" &>/dev/null; then
            print_skip "$name ($("$mise" exec -- "$name" --version 2>/dev/null | head -1))"
            track_skipped "$name (mise)"
            continue
        fi

        print_step "Installing $name via mise"
        if run_cmd "$mise" use -g "$tool"; then
            print_success "$name installed"
            track_installed "$name (mise)"
        else
            print_error "Failed to install $name"
            track_failed "$name (mise)"
        fi
    done
}
