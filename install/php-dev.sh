#!/bin/bash
# shellcheck shell=bash
# ============================================================================
# PHP Dev Tools (macOS dev machine only)
# ============================================================================

install_php_dev_tools() {
    if [[ "$OSTYPE" != "darwin"* ]] || [[ "${IS_MAC_DEV_MACHINE:-false}" != true ]]; then
        return 0
    fi

    print_section "PHP Dev Tools"

    if ! command_exists composer; then
        print_error "composer not found, skipping PHPCS/WPCS setup"
        track_failed "PHPCS/WPCS (composer missing)"
        return 1
    fi

    local composer_home
    composer_home="$(composer global config home --absolute 2>/dev/null || true)"
    if [[ -z "$composer_home" ]]; then
        composer_home="$HOME/.composer"
    fi

    local phpcs_pkg="squizlabs/php_codesniffer"
    local wpcs_pkg="wp-coding-standards/wpcs"
    local need_require=false

    if ! composer global show "$phpcs_pkg" &>/dev/null; then
        need_require=true
    fi
    if ! composer global show "$wpcs_pkg" &>/dev/null; then
        need_require=true
    fi

    if [[ "$need_require" == true ]]; then
        if run_with_spinner "Installing PHPCS + WPCS (Composer global)" \
            composer global require "$phpcs_pkg" "$wpcs_pkg"; then
            print_success "PHPCS + WPCS installed"
            track_installed "PHPCS + WPCS"
        else
            print_error "Failed to install PHPCS + WPCS"
            track_failed "PHPCS + WPCS"
            return 1
        fi
    else
        print_skip "PHPCS + WPCS"
        track_skipped "PHPCS + WPCS"
    fi

    local composer_bin="$composer_home/vendor/bin"
    if [[ -d "$composer_bin" ]]; then
        export PATH="$composer_bin:$PATH"
    fi

    local phpcs_bin="phpcs"
    if ! command_exists phpcs && [[ -x "$composer_bin/phpcs" ]]; then
        phpcs_bin="$composer_bin/phpcs"
    fi

    if ! command_exists "$phpcs_bin" && [[ ! -x "$phpcs_bin" ]]; then
        print_error "phpcs not found after Composer install"
        track_failed "phpcs configuration"
        return 1
    fi

    local wpcs_path="$composer_home/vendor/wp-coding-standards/wpcs"
    if [[ ! -d "$wpcs_path" ]]; then
        print_error "WPCS path not found: $wpcs_path"
        track_failed "phpcs configuration"
        return 1
    fi

    local current_paths
    current_paths="$("$phpcs_bin" --config-show 2>/dev/null | awk -F': ' '/^installed_paths:/ {print $2}')"
    if [[ "$current_paths" == *"$wpcs_path"* ]]; then
        print_skip "phpcs installed_paths (WPCS)"
        track_skipped "phpcs installed_paths (WPCS)"
    else
        local new_paths="$wpcs_path"
        if [[ -n "$current_paths" ]]; then
            new_paths="$current_paths,$wpcs_path"
        fi

        if run_with_spinner "Configuring phpcs WordPress standards" \
            "$phpcs_bin" --config-set installed_paths "$new_paths"; then
            print_success "phpcs configured for WPCS"
            track_installed "phpcs installed_paths (WPCS)"
        else
            print_error "Failed to configure phpcs installed_paths"
            track_failed "phpcs installed_paths (WPCS)"
            return 1
        fi
    fi
}
