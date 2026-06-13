#!/bin/bash
# ============================================================================
# mise (version manager) Installation
# ============================================================================
# mise (https://mise.jdx.dev) is a fast, Rust-based asdf/nvm replacement that
# manages Node (and other runtimes) with per-directory auto-switching and a
# near-zero shell-startup cost. It supersedes NVM in this setup:
#
#   - The runtime modules modules/**/nvm.sh are disabled (renamed #nvm.sh).
#   - modules/common/mise.sh activates mise on every shell.
#   - install/nvm.sh is still sourced for install_npm_global_packages(), but
#     install_nvm/install_node are no longer called.
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

install_mise() {
    print_section "mise (version manager)"

    if command_exists mise || [[ -x "$HOME/.local/bin/mise" ]]; then
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

        if [[ -x "$HOME/.local/bin/mise" ]]; then
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
