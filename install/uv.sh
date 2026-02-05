#!/bin/bash
# ============================================================================
# uv & Python Installation
# ============================================================================

UV_DEFAULT_BIN_DIR="$HOME/.local/bin"

uv_detect_bin() {
    local candidates=(
        "$UV_DEFAULT_BIN_DIR/uv"
        "$HOME/.cargo/bin/uv"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

uv_path_hint() {
    local bin_dir="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_warning "uv not on PATH. Add to ~/.zshrc: export PATH=\"$bin_dir:\$PATH\""
    else
        print_warning "uv not on PATH. Add to ~/.zshrc or ~/.profile: export PATH=\"$bin_dir:\$PATH\""
    fi
}

install_uv() {
    print_section "uv (Python Manager)"

    # Check ~/.local ownership first (common install location)
    if ! check_dir_ownership "$HOME/.local" ".local"; then
        return 1
    fi

    local had_uv_in_path=false
    if command_exists uv; then
        had_uv_in_path=true
        # Verify uv is actually executable
        local uv_path
        uv_path=$(command -v uv)
        if [[ -n "$uv_path" ]]; then
            check_binary_executable "$uv_path" "uv" || return 1
        fi
        print_skip "uv"
        track_skipped "uv"
        return 0
    fi

    print_step "Installing uv"
    if [[ "$VERBOSE" == true ]]; then
        bash -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
    else
        run_with_spinner "Installing uv" bash -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
    fi

    local uv_bin
    uv_bin=$(uv_detect_bin) || true

    if [[ -n "$uv_bin" ]]; then
        local uv_dir
        uv_dir=$(dirname "$uv_bin")
        export PATH="$uv_dir:$PATH"
        print_success "uv installed"
        track_installed "uv"

        if [[ "$had_uv_in_path" != true ]]; then
            uv_path_hint "$uv_dir"
        fi
    else
        print_error "uv installation failed"
        track_failed "uv"
        return 1
    fi
}

uv_python_installed() {
    local list_cmd=("uv" "python" "list")
    if uv python list --help 2>/dev/null | grep -q -- "--installed"; then
        list_cmd=("uv" "python" "list" "--installed")
    fi

    "${list_cmd[@]}" 2>/dev/null | grep -Eq '[0-9]+\.[0-9]+'
}

install_python_uv() {
    print_section "Python (uv)"

    if ! command_exists uv; then
        print_error "uv not available, skipping Python installation"
        track_failed "Python (uv not available)"
        return 1
    fi

    if uv_python_installed; then
        local py_version=""
        if command_exists python; then
            py_version=$(python --version 2>&1 | awk '{print $2}')
        fi
        if [[ -n "$py_version" ]]; then
            print_skip "Python (${py_version})"
            track_skipped "Python ${py_version}"
        else
            print_skip "Python"
            track_skipped "Python"
        fi
        return 0
    fi

    local default_flag=""
    if uv python install --help 2>/dev/null | grep -q -- "--default"; then
        default_flag="--default"
    fi

    print_step "Installing Python (stable)"
    if [[ "$VERBOSE" == true ]]; then
        uv python install $default_flag
    else
        run_with_spinner "Installing Python (stable)" uv python install $default_flag
    fi

    if command_exists python; then
        local py_version
        py_version=$(python --version 2>&1 | awk '{print $2}')
        print_success "Python ${py_version} installed"
        track_installed "Python ${py_version}"
    else
        print_error "Python installation failed"
        track_failed "Python"
        return 1
    fi
}
