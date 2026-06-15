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
    version=$(github_latest_version "ajeetdsouza/zoxide")
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest zoxide version"
        track_failed "zoxide"
        return 0
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

    # eza only publishes a musl build for x86_64; aarch64 is gnu-only. Picking
    # the wrong libc 404s the release asset, so map each arch to its full target
    # triple rather than assuming musl everywhere.
    local target
    case "$(uname -m)" in
        x86_64)  target="x86_64-unknown-linux-musl" ;;
        aarch64) target="aarch64-unknown-linux-gnu" ;;
        *)
            print_warning "No prebuilt eza binary for $(uname -m), skipping"
            track_skipped "eza (no prebuilt for $(uname -m))"
            return 0
            ;;
    esac

    local version
    version=$(github_latest_version "eza-community/eza")
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest eza version"
        track_failed "eza"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/eza-community/eza/releases/download/v${version}/eza_${target}.tar.gz"

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

install_glow_prebuilt() {
    print_section "Glow (prebuilt)"

    if command_exists glow; then
        print_skip "glow"
        track_skipped "glow"
        return 0
    fi

    print_package "glow"

    local arch
    case "$(uname -m)" in
        x86_64)        arch="x86_64" ;;
        aarch64)       arch="arm64" ;;
        armv7l|armv6l) arch="arm" ;;
        *)
            print_warning "No prebuilt glow binary for $(uname -m), skipping"
            track_skipped "glow (no prebuilt for $(uname -m))"
            return 0
            ;;
    esac

    local version
    version=$(github_latest_version "charmbracelet/glow")
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest glow version"
        track_failed "glow"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/charmbracelet/glow/releases/download/v${version}/glow_${version}_Linux_${arch}.tar.gz"

    if run_with_spinner "Downloading glow v${version}" curl -fsSL "$url" -o "${tmp_dir}/glow.tar.gz" && \
       tar xzf "${tmp_dir}/glow.tar.gz" -C "$tmp_dir" && \
       sudo install "$(find "$tmp_dir" -type f -name glow | head -n1)" /usr/local/bin/glow; then
        print_success "glow v${version} installed"
        track_installed "glow"
    else
        print_error "Failed to install glow"
        track_failed "glow"
    fi

    rm -rf "$tmp_dir"
}

install_carapace_prebuilt() {
    print_section "Carapace (prebuilt)"

    if command_exists carapace; then
        print_skip "carapace"
        track_skipped "carapace"
        return 0
    fi

    print_package "carapace"

    # carapace-bin ships amd64/arm64 only — no 32-bit ARM (Pi) build.
    local arch
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *)
            print_warning "No prebuilt carapace binary for $(uname -m), skipping"
            track_skipped "carapace (no prebuilt for $(uname -m))"
            return 0
            ;;
    esac

    local version
    version=$(github_latest_version "carapace-sh/carapace-bin")
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest carapace version"
        track_failed "carapace"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/carapace-sh/carapace-bin/releases/download/v${version}/carapace-bin_${version}_linux_${arch}.tar.gz"

    if run_with_spinner "Downloading carapace v${version}" curl -fsSL "$url" -o "${tmp_dir}/carapace.tar.gz" && \
       tar xzf "${tmp_dir}/carapace.tar.gz" -C "$tmp_dir" && \
       sudo install "$(find "$tmp_dir" -type f -name carapace | head -n1)" /usr/local/bin/carapace; then
        print_success "carapace v${version} installed"
        track_installed "carapace"
    else
        print_error "Failed to install carapace"
        track_failed "carapace"
    fi

    rm -rf "$tmp_dir"
}

# glow + carapace are Go binaries with no apt/cargo package — fetch prebuilt
# release binaries on apt systems (macOS gets them via Homebrew).
install_charm_prebuilt_bins() {
    install_glow_prebuilt
    install_carapace_prebuilt
}

install_prebuilt_bins() {
    install_zoxide_prebuilt
    install_eza_prebuilt
    install_charm_prebuilt_bins
}
