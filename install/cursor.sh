#!/bin/bash
# shellcheck shell=bash
# ============================================================================
# Cursor Setup (macOS dev machine only)
# ============================================================================

CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
CURSOR_SETTINGS_SOURCE="$SCRIPT_DIR/configs/cursor/User/settings.json"
CURSOR_KEYBINDINGS_SOURCE="$SCRIPT_DIR/configs/cursor/User/keybindings.json"
CURSOR_EXTENSIONS_SOURCE="$SCRIPT_DIR/configs/cursor/extensions.txt"

resolve_cursor_cli() {
    if command_exists cursor; then
        echo "cursor"
        return 0
    fi

    local app_bin="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    if [[ -x "$app_bin" ]]; then
        echo "$app_bin"
        return 0
    fi

    return 1
}

backup_cursor_file() {
    local target="$1"
    if [[ -f "$target" ]]; then
        mv "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

install_cursor_profile() {
    if [[ "$OSTYPE" != "darwin"* ]] || [[ "${IS_MAC_DEV_MACHINE:-false}" != true ]]; then
        return 0
    fi

    print_section "Cursor IDE Setup"

    mkdir -p "$CURSOR_USER_DIR"

    if [[ -f "$CURSOR_SETTINGS_SOURCE" ]]; then
        backup_cursor_file "$CURSOR_USER_DIR/settings.json"
        cp "$CURSOR_SETTINGS_SOURCE" "$CURSOR_USER_DIR/settings.json"
        print_success "Cursor settings seeded"
        track_installed "Cursor settings"
    else
        print_warning "Cursor settings seed missing: $CURSOR_SETTINGS_SOURCE"
        track_failed "Cursor settings"
    fi

    if [[ -f "$CURSOR_KEYBINDINGS_SOURCE" ]]; then
        backup_cursor_file "$CURSOR_USER_DIR/keybindings.json"
        cp "$CURSOR_KEYBINDINGS_SOURCE" "$CURSOR_USER_DIR/keybindings.json"
        print_success "Cursor keybindings seeded"
        track_installed "Cursor keybindings"
    else
        print_warning "Cursor keybindings seed missing: $CURSOR_KEYBINDINGS_SOURCE"
        track_failed "Cursor keybindings"
    fi

    if [[ ! -f "$CURSOR_EXTENSIONS_SOURCE" ]]; then
        print_warning "Cursor extensions list missing: $CURSOR_EXTENSIONS_SOURCE"
        track_failed "Cursor extensions"
        return 0
    fi

    local cursor_cli
    cursor_cli="$(resolve_cursor_cli || true)"
    if [[ -z "$cursor_cli" ]]; then
        print_warning "Cursor CLI not found; skipping extension install"
        print_info "Open Cursor once, install 'Shell Command: Install cursor command', then re-run."
        track_skipped "Cursor extensions (CLI unavailable)"
        return 0
    fi

    local installed_exts
    installed_exts="$("$cursor_cli" --list-extensions 2>/dev/null || true)"
    local ext

    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        if printf "%s\n" "$installed_exts" | grep -qx "$ext"; then
            print_skip "$ext"
            track_skipped "$ext"
        else
            print_package "$ext"
            if run_with_spinner "Installing Cursor extension $ext" \
                "$cursor_cli" --install-extension "$ext"; then
                print_success "$ext installed"
                track_installed "$ext"
            else
                print_error "Failed to install extension $ext"
                track_failed "$ext"
            fi
        fi
    done < "$CURSOR_EXTENSIONS_SOURCE"
}
