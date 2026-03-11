# shellcheck shell=bash
# ============================================================================
# Prebuilt Binary Installation (for --light mode)
# ============================================================================
# Downloads prebuilt binaries from GitHub Releases instead of compiling
# via Cargo. Used in light/server mode to avoid long compile times.
# ============================================================================

install_zoxide_prebuilt() {
    print_section "Zoxide (prebuilt)"

    if command_exists zoxide; then
        print_skip "zoxide"
        track_skipped "zoxide"
        return 0
    fi

    print_package "zoxide"

    local arch
    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)
            print_error "Unsupported architecture for zoxide: $(uname -m)"
            track_failed "zoxide"
            return 1
            ;;
    esac

    local version
    version=$(curl -fsSL "https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest zoxide version"
        track_failed "zoxide"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/ajeetdsouza/zoxide/releases/download/v${version}/zoxide-${version}-${arch}-unknown-linux-musl.tar.gz"

    if run_with_spinner "Downloading zoxide v${version}" curl -fsSL "$url" -o "${tmp_dir}/zoxide.tar.gz" && \
       tar xzf "${tmp_dir}/zoxide.tar.gz" -C "$tmp_dir" && \
       sudo install "${tmp_dir}/zoxide" /usr/local/bin/zoxide; then
        print_success "zoxide v${version} installed"
        track_installed "zoxide"
    else
        print_error "Failed to install zoxide"
        track_failed "zoxide"
    fi

    rm -rf "$tmp_dir"
}

install_eza_prebuilt() {
    print_section "Eza (prebuilt)"

    if command_exists eza; then
        print_skip "eza"
        track_skipped "eza"
        return 0
    fi

    print_package "eza"

    local arch
    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)
            print_warning "No prebuilt eza binary for $(uname -m), skipping"
            track_skipped "eza (no prebuilt for $(uname -m))"
            return 0
            ;;
    esac

    local version
    version=$(curl -fsSL "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest eza version"
        track_failed "eza"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/eza-community/eza/releases/download/v${version}/eza_${arch}-unknown-linux-musl.tar.gz"

    if run_with_spinner "Downloading eza v${version}" curl -fsSL "$url" -o "${tmp_dir}/eza.tar.gz" && \
       tar xzf "${tmp_dir}/eza.tar.gz" -C "$tmp_dir" && \
       sudo install "${tmp_dir}/eza" /usr/local/bin/eza; then
        print_success "eza v${version} installed"
        track_installed "eza"
    else
        print_error "Failed to install eza"
        track_failed "eza"
    fi

    rm -rf "$tmp_dir"
}

install_prebuilt_bins() {
    install_zoxide_prebuilt
    install_eza_prebuilt
}
