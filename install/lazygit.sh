#!/bin/bash
# ============================================================================
# Lazygit Installation
# ============================================================================

install_lazygit() {
    print_section "Lazygit"

    if command_exists lazygit; then
        print_skip "Lazygit"
        track_skipped "Lazygit"
        return 0
    fi

    if command_exists brew; then
        # macOS / Linuxbrew
        print_package "lazygit"
        if run_with_spinner "Installing Lazygit" brew install "lazygit"; then
            print_success "Lazygit installed"
            track_installed "Lazygit"
        else
            print_error "Failed to install Lazygit"
            track_failed "Lazygit"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux: download binary from GitHub Releases
        print_package "lazygit"

        local arch
        case "$(uname -m)" in
            x86_64)  arch="x86_64" ;;
            aarch64) arch="arm64" ;;
            armv*)   arch="armv6" ;;
            *)
                print_error "Unsupported architecture: $(uname -m)"
                track_failed "Lazygit"
                return 1
                ;;
        esac

        local version
        version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        if [[ -z "$version" ]]; then
            print_error "Failed to fetch latest Lazygit version"
            track_failed "Lazygit"
            return 1
        fi

        local tmp_dir
        tmp_dir=$(mktemp -d)
        local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz"

        if run_with_spinner "Downloading Lazygit v${version}" curl -fsSL "$url" -o "${tmp_dir}/lazygit.tar.gz" && \
           tar xzf "${tmp_dir}/lazygit.tar.gz" -C "$tmp_dir" && \
           sudo install "${tmp_dir}/lazygit" /usr/local/bin/lazygit; then
            print_success "Lazygit v${version} installed"
            track_installed "Lazygit"
        else
            print_error "Failed to install Lazygit"
            track_failed "Lazygit"
        fi

        rm -rf "$tmp_dir"
    else
        print_error "No supported install method for Lazygit on this platform"
        track_failed "Lazygit"
        return 1
    fi
}
