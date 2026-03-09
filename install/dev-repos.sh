#!/bin/bash
# ============================================================================
# Dev Repos Installation
# ============================================================================
# Clones or updates development repositories to ~/dev.
# Runs on dev machines (macOS dev, Docker containers).
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

    mkdir -p "$DEV_REPOS_DIR"

    for repo in "${DEV_REPOS[@]}"; do
        local repo_name="${repo##*/}"
        local repo_dir="$DEV_REPOS_DIR/$repo_name"
        local repo_url="https://github.com/$repo.git"

        if [[ -d "$repo_dir/.git" ]]; then
            # Already cloned — pull latest
            print_step "Updating $repo_name"
            if run_with_spinner "Pulling $repo_name" git -C "$repo_dir" pull --ff-only; then
                print_success "$repo_name updated"
                track_skipped "$repo_name (updated)"
            else
                print_warning "$repo_name pull failed (diverged?), skipping"
                track_skipped "$repo_name (pull failed)"
            fi
        else
            # Fresh clone
            print_package "$repo_name"
            if run_with_spinner "Cloning $repo_name" git clone "$repo_url" "$repo_dir"; then
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
