#!/bin/bash
# ============================================================================
# Lazydocker Installation
# ============================================================================

install_lazydocker() {
    print_section "Lazydocker"

    if command_exists lazydocker; then
        print_skip "Lazydocker"
        track_skipped "Lazydocker"
        return 0
    fi

    if command_exists brew; then
        print_package "lazydocker"
        if run_with_spinner "Installing Lazydocker" brew install "lazydocker"; then
            print_success "Lazydocker installed"
            track_installed "Lazydocker"
        else
            print_error "Failed to install Lazydocker"
            track_failed "Lazydocker"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_package "lazydocker"

        local arch
        case "$(uname -m)" in
            x86_64)  arch="x86_64" ;;
            aarch64) arch="arm64" ;;
            armv*)   arch="armv6" ;;
            *)
                print_error "Unsupported architecture: $(uname -m)"
                track_failed "Lazydocker"
                return 1
                ;;
        esac

        local version
        version=$(github_latest_version "jesseduffield/lazydocker")
        if [[ -z "$version" ]]; then
            print_error "Failed to fetch latest Lazydocker version"
            track_failed "Lazydocker"
            return 0
        fi

        local tmp_dir
        tmp_dir=$(mktemp -d)
        local url="https://github.com/jesseduffield/lazydocker/releases/download/v${version}/lazydocker_${version}_Linux_${arch}.tar.gz"

        if run_with_spinner "Downloading Lazydocker v${version}" curl -fsSL "$url" -o "${tmp_dir}/lazydocker.tar.gz" && \
           tar xzf "${tmp_dir}/lazydocker.tar.gz" -C "$tmp_dir" && \
           sudo install "${tmp_dir}/lazydocker" /usr/local/bin/lazydocker; then
            print_success "Lazydocker v${version} installed"
            track_installed "Lazydocker"
        else
            print_error "Failed to install Lazydocker"
            track_failed "Lazydocker"
        fi

        rm -rf "$tmp_dir"
    else
        print_error "No supported install method for Lazydocker on this platform"
        track_failed "Lazydocker"
        return 1
    fi
}
