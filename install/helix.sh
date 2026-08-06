#!/bin/bash
# ============================================================================
# Helix editor
# ============================================================================
# macOS gets `helix` from BREW_PACKAGES. This file covers what brew can't:
#
#   1. install_helix — the Linux route. Helix is NOT in Ubuntu 22.04/24.04 or
#      Raspberry Pi OS repos (it only landed in Ubuntu 24.10 / Debian trixie),
#      and `cargo install helix-term` deliberately does not install the runtime
#      directory, leaving you with no grammars or queries. So: the official
#      release tarball, which bundles hx + runtime together.
#   2. deploy_helix_config — the config + Cobalt2 theme symlinks, plus the
#      runtime-directory repair described above _link_helix_runtime.
#
# Runtime discovery: Helix looks for `<exe_dir>/../runtime` before falling back
# to ~/.config/helix/runtime. std::env::current_exe() reads /proc/self/exe on
# Linux, which is already symlink-resolved — so installing to /opt/helix/bin/hx
# with the runtime at /opt/helix/runtime resolves correctly even though PATH
# only ever sees the /usr/local/bin/hx symlink. No HELIX_RUNTIME export needed.
# ============================================================================

HELIX_PREFIX="/opt/helix"

install_helix() {
    print_section "Helix"

    if command_exists hx; then
        print_skip "helix ($(hx --version 2>/dev/null | head -n1))"
        track_skipped "helix"
        return 0
    fi

    print_package "helix"

    # Upstream ships x86_64 and aarch64 Linux builds only — no 32-bit ARM, so
    # a Pi running the armhf image gets skipped rather than half-installed.
    local arch
    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)
            print_warning "No prebuilt helix binary for $(uname -m), skipping"
            track_skipped "helix (no prebuilt for $(uname -m))"
            return 0
            ;;
    esac

    local version
    version=$(github_latest_version "helix-editor/helix")
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch latest helix version"
        track_failed "helix"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local url="https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-${arch}-linux.tar.xz"

    # tar -J needs xz; APT_PACKAGES carries xz-utils, but --light installs run
    # this before nothing guarantees it, so fail loudly rather than silently.
    if ! command_exists xz; then
        print_error "xz not found — cannot unpack the helix tarball"
        track_failed "helix"
        rm -rf "$tmp_dir"
        return 0
    fi

    if run_with_spinner "Downloading helix ${version}" curl -fsSL "$url" -o "${tmp_dir}/helix.tar.xz" && \
       tar xJf "${tmp_dir}/helix.tar.xz" -C "$tmp_dir"; then
        local extracted
        extracted=$(find "$tmp_dir" -maxdepth 1 -type d -name 'helix-*' | head -n1)

        if [[ -z "$extracted" ]] || [[ ! -x "$extracted/hx" ]] || [[ ! -d "$extracted/runtime" ]]; then
            print_error "helix tarball did not contain the expected hx + runtime/"
            track_failed "helix"
            rm -rf "$tmp_dir"
            return 0
        fi

        # Replace wholesale: a stale runtime/ from an older version mixed with a
        # new hx is the one combination that breaks grammars at load time.
        sudo rm -rf "$HELIX_PREFIX"
        sudo mkdir -p "$HELIX_PREFIX/bin"
        sudo cp "$extracted/hx" "$HELIX_PREFIX/bin/hx"
        sudo cp -R "$extracted/runtime" "$HELIX_PREFIX/runtime"
        sudo chmod 755 "$HELIX_PREFIX/bin/hx"
        sudo ln -sf "$HELIX_PREFIX/bin/hx" /usr/local/bin/hx

        print_success "helix ${version} installed to $HELIX_PREFIX"
        track_installed "helix"
    else
        print_error "Failed to install helix"
        track_failed "helix"
    fi

    rm -rf "$tmp_dir"
}

# ----------------------------------------------------------------------------
# Config + theme
# ----------------------------------------------------------------------------
# Symlinked, not copied. Helix never rewrites config.toml at runtime — `:theme`
# and `:set` are session-only — so there is no atomic write-then-rename to
# clobber the link, which is what forces the copy in install/herdr.sh and
# install/warp.sh. Symlinks mean a repo edit lands on every machine on pull.
deploy_helix_config() {
    print_section "Helix Configuration"

    local config_dir="$HOME/.config/helix"
    local themes_dir="$config_dir/themes"
    local config_source="$SCRIPT_DIR/configs/helix/config.toml"
    local theme_source="$SCRIPT_DIR/configs/helix/themes/cobalt2.toml"

    if [[ ! -f "$config_source" ]] || [[ ! -f "$theme_source" ]]; then
        print_warning "helix config templates missing, skipping"
        track_skipped "helix config (templates missing)"
        return 0
    fi

    mkdir -p "$themes_dir"

    _link_helix_file "$theme_source" "$themes_dir/cobalt2.toml" "helix cobalt2 theme"
    _link_helix_file "$config_source" "$config_dir/config.toml" "helix config"
    _link_helix_runtime "$config_dir"
}

# ----------------------------------------------------------------------------
# Runtime directory
# ----------------------------------------------------------------------------
# Helix needs its runtime/ (tree-sitter grammars + queries) or every language
# silently loses highlighting, indent and textobjects — `hx --health` shows a
# column of ✘ and nothing errors out.
#
# The Homebrew bottle bakes in an absolute /opt/homebrew/... runtime path at
# build time. On a custom prefix — and this repo already supports one, see
# preload_configs/macos/path.sh handling $HOME/homebrew — that path does not
# exist, and the exe-relative fallback misses too because brew puts the binary
# in bin/ and the runtime in libexec/. Result: helix installs "successfully"
# with all highlighting dead.
#
# ~/.config/helix/runtime is Helix's highest-priority lookup, so pointing it at
# the real directory fixes every prefix. We link the version-stable opt/ path,
# not the Cellar path, so a `brew upgrade helix` does not strand it.
_link_helix_runtime() {
    local config_dir="$1"
    local target="$config_dir/runtime"
    local source=""

    if command_exists brew; then
        local brew_runtime
        brew_runtime="$(brew --prefix 2>/dev/null)/opt/helix/libexec/runtime"
        [[ -d "$brew_runtime" ]] && source="$brew_runtime"
    fi

    # Our own tarball install (install_helix) is already exe-relative, but
    # linking it keeps behaviour identical across platforms. Distro packages
    # scatter the runtime, so check the usual spots too.
    if [[ -z "$source" ]]; then
        local candidate
        for candidate in "$HELIX_PREFIX/runtime" \
                         /usr/lib/helix/runtime \
                         /usr/share/helix/runtime \
                         /usr/local/lib/helix/runtime; do
            if [[ -d "$candidate" ]]; then
                source="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$source" ]]; then
        print_skip "helix runtime (no runtime directory found)"
        track_skipped "helix runtime"
        return 0
    fi

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        print_skip "helix runtime symlink"
        track_skipped "helix runtime"
        return 0
    fi

    # A real directory here is someone's hand-built runtime — never delete it.
    if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
        print_skip "helix runtime (real directory present, leaving it alone)"
        track_skipped "helix runtime (user-managed)"
        return 0
    fi

    print_step "Linking helix runtime"
    ln -sfn "$source" "$target"
    print_success "$target → $source"
    track_installed "helix runtime"
}

# Link $1 → $2, backing up a real file but silently replacing a stale symlink.
_link_helix_file() {
    local source="$1" target="$2" label="$3"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        print_skip "$label symlink"
        track_skipped "$label"
        return 0
    fi

    if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
        print_step "Backing up existing $(basename "$target")"
        mv "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backup created"
    fi

    rm -f "$target"
    print_step "Linking $label"
    ln -s "$source" "$target"
    print_success "$target → $source"
    track_installed "$label"
}
