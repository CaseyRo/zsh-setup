#!/bin/bash
# ============================================================================
# Dev Repos Installation
# ============================================================================
# Clones or updates development repositories to ~/dev.
# Gated on `gh auth status` — an authenticated gh CLI is the signal that the
# user is a dev who wants git wired up, and gives us a token so private repos
# (e.g. casey-claude-setup) clone without an interactive credential prompt.
# ============================================================================

DEV_REPOS_DIR="$HOME/dev"

install_dev_repos() {
    if [[ ${#DEV_REPOS[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Dev Repos"

    if ! command_exists git; then
        print_error "git is required to install dev repos"
        for repo in "${DEV_REPOS[@]}"; do
            track_failed "$repo"
        done
        return 1
    fi

    if ! command_exists gh; then
        print_skip "Dev repos (gh CLI not installed)"
        print_info "Install gh and run: gh auth login && ./install.sh"
        track_skipped "Dev repos (no gh)"
        return 0
    fi

    if ! gh auth status &>/dev/null; then
        print_skip "Dev repos (gh not authenticated)"
        print_info "Run: gh auth login   then re-run ./install.sh"
        print_info "Skipping prevents interactive credential prompts on private repos."
        track_skipped "Dev repos (gh not authed)"
        return 0
    fi

    mkdir -p "$DEV_REPOS_DIR"

    for repo in "${DEV_REPOS[@]}"; do
        local repo_name="${repo##*/}"
        local repo_dir="$DEV_REPOS_DIR/$repo_name"

        if [[ -d "$repo_dir/.git" ]]; then
            # Already cloned — pull latest. gh's credential helper makes this
            # work for private repos too without prompting.
            print_step "Updating $repo_name"
            if run_with_spinner "Pulling $repo_name" git -C "$repo_dir" pull --ff-only; then
                print_success "$repo_name updated"
                track_skipped "$repo_name (updated)"
            else
                print_warning "$repo_name pull failed (diverged?), skipping"
                track_skipped "$repo_name (pull failed)"
            fi
        else
            # Fresh clone via gh — uses the token, never prompts.
            print_package "$repo_name"
            if run_with_spinner "Cloning $repo_name" gh repo clone "$repo" "$repo_dir"; then
                print_success "$repo_name cloned to ~/dev/$repo_name"
                track_installed "$repo_name"
            else
                print_error "Failed to clone $repo_name"
                track_failed "$repo_name"
            fi
        fi
    done

    # Run casey-claude-setup installer if present
    local claude_setup_dir="$DEV_REPOS_DIR/casey-claude-setup"
    if [[ -d "$claude_setup_dir" ]] && [[ -f "$claude_setup_dir/install.sh" ]]; then
        print_step "Running casey-claude-setup installer"
        if bash "$claude_setup_dir/install.sh"; then
            print_success "casey-claude-setup configured"
        else
            print_warning "casey-claude-setup installer returned non-zero (may need manual setup)"
        fi
    fi
}
