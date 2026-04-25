# shellcheck shell=bash
# ============================================================================
# Syncthing Installation & Hub Bootstrap
# ============================================================================
# Installs Syncthing, runs it as the main user, and (when ZSH_SETUP_SYNCTHING_HUB_ID
# is set in ~/.env.sh) wires this host to a single "hub" device with the
# introducer flag — so all other devices the hub knows about are automatically
# shared into this host. No reinventing the wheel: Syncthing's introducer
# feature is the canonical mechanism for this pattern.
#
# Required env (in ~/.env.sh):
#   ZSH_SETUP_SYNCTHING_HUB_ID    Device ID of the hub (e.g. ABCDEFG-...)
# Optional:
#   ZSH_SETUP_SYNCTHING_HUB_NAME    Friendly name for the hub (default: "hub")
#   ZSH_SETUP_SYNCTHING_DEVICE_NAME Override this host's display name
#   ZSH_SETUP_SYNCTHING_GUI_ADDRESS GUI bind address (default: 0.0.0.0:8384)
#   ZSH_SETUP_SYNCTHING_GUI_USER    GUI username (default: $USER)
# Flags:
#   --syncthing-wipe   Force wipe any existing Syncthing state before install
# ============================================================================

# Local API address — Syncthing always serves the API on the GUI listener,
# but we always reach it from this host via loopback for safety.
# shellcheck disable=SC2034
SYNCTHING_API_HOST="127.0.0.1:8384"
SYNCTHING_MARKER_NAME=".zsh-setup-managed"

_syncthing_config_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/Syncthing"
    else
        # Linux: prefer XDG, fall back to ~/.config/syncthing then ~/.local/state/syncthing
        if [[ -d "$HOME/.local/state/syncthing" ]]; then
            echo "$HOME/.local/state/syncthing"
        else
            echo "${XDG_CONFIG_HOME:-$HOME/.config}/syncthing"
        fi
    fi
}

_syncthing_is_running() {
    curl -fsS --max-time 2 "http://${SYNCTHING_API_HOST}/rest/system/ping" >/dev/null 2>&1
}

_syncthing_stop_service() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew services stop syncthing >/dev/null 2>&1 || true
        fi
        # Belt-and-braces: kill any stray launchd agents / processes
        launchctl bootout "gui/$(id -u)/syncthing" 2>/dev/null || true
        pkill -u "$USER" -x syncthing 2>/dev/null || true
    else
        systemctl --user stop syncthing.service 2>/dev/null || true
        systemctl --user disable syncthing.service 2>/dev/null || true
        pkill -u "$USER" -x syncthing 2>/dev/null || true
    fi
}

_syncthing_start_service() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew services start syncthing >/dev/null 2>&1
            return $?
        fi
        return 1
    fi

    # Linux: enable lingering so the service survives logout, then start
    if command_exists loginctl; then
        loginctl enable-linger "$USER" >/dev/null 2>&1 || true
    fi

    if ! systemctl --user daemon-reload >/dev/null 2>&1; then
        return 1
    fi
    systemctl --user enable --now syncthing.service >/dev/null 2>&1
}

_syncthing_wait_ready() {
    local max_tries=30
    local i=0
    while (( i < max_tries )); do
        if _syncthing_is_running; then
            return 0
        fi
        sleep 1
        ((i++))
    done
    return 1
}

_syncthing_apikey() {
    local config_dir
    config_dir="$(_syncthing_config_dir)"
    local config_xml="$config_dir/config.xml"
    [[ -f "$config_xml" ]] || return 1

    # Extract <apikey>...</apikey> from the <gui> stanza. POSIX sed (works on macOS too).
    sed -n 's|.*<apikey>\(.*\)</apikey>.*|\1|p' "$config_xml" | head -n1
}

_syncthing_my_id() {
    local apikey="$1"
    curl -fsS --max-time 5 -H "X-API-Key: $apikey" \
        "http://${SYNCTHING_API_HOST}/rest/system/status" 2>/dev/null \
        | sed -n 's|.*"myID": *"\([^"]*\)".*|\1|p' | head -n1
}

_syncthing_has_device() {
    local apikey="$1" device_id="$2"
    curl -fsS --max-time 5 -H "X-API-Key: $apikey" \
        "http://${SYNCTHING_API_HOST}/rest/config/devices" 2>/dev/null \
        | grep -q "\"deviceID\": *\"$device_id\""
}

# ============================================================================
# GUI credentials
# ============================================================================
# Stored in $XDG_CONFIG_HOME/zsh-setup/syncthing-gui (mode 600). Generated once,
# reused across re-runs so the user doesn't get a new password every install.

_syncthing_creds_file() {
    local base="${XDG_CONFIG_HOME:-$HOME/.config}/zsh-setup"
    mkdir -p "$base" 2>/dev/null || true
    chmod 700 "$base" 2>/dev/null || true
    echo "$base/syncthing-gui"
}

_syncthing_load_or_make_creds() {
    local creds_file
    creds_file="$(_syncthing_creds_file)"

    if [[ -f "$creds_file" ]]; then
        # shellcheck disable=SC1090
        source "$creds_file"
    fi

    if [[ -z "${SYNCTHING_GUI_USER:-}" ]]; then
        SYNCTHING_GUI_USER="${ZSH_SETUP_SYNCTHING_GUI_USER:-${USER:-admin}}"
    fi

    if [[ -z "${SYNCTHING_GUI_PASSWORD:-}" ]]; then
        if command_exists openssl; then
            SYNCTHING_GUI_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)
        else
            SYNCTHING_GUI_PASSWORD=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 20)
        fi
        cat > "$creds_file" <<EOF
# Managed by zsh-setup — Syncthing GUI credentials
# Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
SYNCTHING_GUI_USER="$SYNCTHING_GUI_USER"
SYNCTHING_GUI_PASSWORD="$SYNCTHING_GUI_PASSWORD"
EOF
        chmod 600 "$creds_file" 2>/dev/null || true
    fi
}

_syncthing_apply_gui_config() {
    local apikey="$1" address="$2" user="$3" password="$4"

    # PATCH /rest/config/gui — Syncthing accepts plaintext password and hashes it.
    local payload
    payload=$(cat <<EOF
{
  "address": "$address",
  "user": "$user",
  "password": "$password"
}
EOF
)

    curl -fsS --max-time 5 -X PATCH \
        -H "X-API-Key: $apikey" \
        -H "Content-Type: application/json" \
        "http://${SYNCTHING_API_HOST}/rest/config/gui" \
        -d "$payload" >/dev/null 2>&1
}

# ============================================================================
# Public: detect, wipe, install
# ============================================================================

_syncthing_should_skip_platform() {
    # Docker — no service manager for users; skip cleanly
    if is_docker; then
        return 0
    fi

    # macOS gated by networked-services opt-in
    if [[ "$OSTYPE" == "darwin"* ]] && [[ "$ALLOW_MAC_NETWORKED_SERVICES" != true ]]; then
        return 0
    fi

    # Linux without systemd --user is a non-starter for the daemonized setup
    if [[ "$OSTYPE" == "linux-gnu"* ]] && ! command_exists systemctl; then
        return 0
    fi

    return 1
}

_syncthing_wipe_existing() {
    local config_dir
    config_dir="$(_syncthing_config_dir)"
    local marker="$config_dir/$SYNCTHING_MARKER_NAME"

    # Already managed by us → nothing to wipe.
    if [[ -f "$marker" ]]; then
        return 0
    fi

    # No prior config to wipe. (Binary alone is fine — that's just `brew install`.)
    if [[ ! -d "$config_dir" ]]; then
        return 0
    fi

    # Existing config dir detected and not managed by us.
    # Confirm (or auto-yes via --syncthing-wipe / -y).
    if [[ "$SYNCTHING_WIPE" != true ]] && [[ "$YES_TO_ALL" != true ]]; then
        print_warning "Existing Syncthing install detected at $config_dir"
        if ! ui_confirm "Wipe it for a clean zsh-setup managed install?"; then
            print_info "Leaving existing Syncthing install in place — skipping configuration"
            return 1
        fi
    else
        print_info "Wiping existing Syncthing state at $config_dir"
    fi

    print_step "Stopping any running Syncthing service"
    _syncthing_stop_service
    sleep 1

    if [[ -d "$config_dir" ]]; then
        print_step "Removing $config_dir"
        rm -rf "$config_dir"
    fi

    # Also wipe legacy Linux state dir if both existed
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -d "$HOME/.local/state/syncthing" ]]; then
        rm -rf "$HOME/.local/state/syncthing"
    fi

    return 0
}

_syncthing_install_binary() {
    if command_exists syncthing; then
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command_exists brew; then
            print_error "Homebrew required to install Syncthing on macOS"
            return 1
        fi
        run_with_spinner "Installing syncthing via brew" brew install syncthing
        return $?
    fi

    if should_use_apt; then
        run_with_spinner "Installing syncthing via apt" sudo apt-get install -y syncthing
        return $?
    fi

    print_error "No supported package manager for syncthing"
    return 1
}

_syncthing_first_start() {
    print_step "Starting Syncthing as user '$USER'"
    if ! _syncthing_start_service; then
        print_error "Failed to start syncthing service"
        return 1
    fi

    print_step "Waiting for Syncthing API to come up"
    if ! _syncthing_wait_ready; then
        print_error "Syncthing API did not respond within 30s"
        return 1
    fi
    print_success "Syncthing is running"
    return 0
}

_syncthing_set_device_name() {
    local apikey="$1" my_id="$2" desired_name="$3"
    [[ -n "$apikey" && -n "$my_id" && -n "$desired_name" ]] || return 1

    curl -fsS --max-time 5 -X PATCH \
        -H "X-API-Key: $apikey" \
        -H "Content-Type: application/json" \
        "http://${SYNCTHING_API_HOST}/rest/config/devices/$my_id" \
        -d "{\"name\": \"$desired_name\"}" >/dev/null 2>&1
}

_syncthing_add_hub_device() {
    local apikey="$1" hub_id="$2" hub_name="$3"

    if _syncthing_has_device "$apikey" "$hub_id"; then
        return 0
    fi

    local payload
    payload=$(cat <<EOF
{
  "deviceID": "$hub_id",
  "name": "$hub_name",
  "introducer": true,
  "autoAcceptFolders": true,
  "addresses": ["dynamic"],
  "compression": "metadata"
}
EOF
)

    curl -fsS --max-time 5 -X POST \
        -H "X-API-Key: $apikey" \
        -H "Content-Type: application/json" \
        "http://${SYNCTHING_API_HOST}/rest/config/devices" \
        -d "$payload" >/dev/null 2>&1
}

_syncthing_write_marker() {
    local config_dir
    config_dir="$(_syncthing_config_dir)"
    [[ -d "$config_dir" ]] || return 0

    local marker="$config_dir/$SYNCTHING_MARKER_NAME"
    {
        echo "# Managed by zsh-setup ($SCRIPT_DIR)"
        echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "host=$(hostname -s 2>/dev/null || hostname)"
        echo "hub_id=$ZSH_SETUP_SYNCTHING_HUB_ID"
    } > "$marker" 2>/dev/null || true
}

# ============================================================================
# Orchestration entrypoints (called from install/core.sh main())
# ============================================================================

install_syncthing() {
    print_section "Syncthing"

    if [[ "$LIGHT_MODE" == true ]]; then
        # Light mode is for tiny VPSes — Syncthing's not the right fit there
        print_skip "Syncthing (light mode)"
        track_skipped "Syncthing (light mode)"
        return 0
    fi

    if _syncthing_should_skip_platform; then
        if is_docker; then
            print_skip "Syncthing (Docker container — needs a host service manager)"
            track_skipped "Syncthing (Docker)"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            print_skip "Syncthing (macOS networked services disabled)"
            track_skipped "Syncthing (macOS networked services disabled)"
        else
            print_skip "Syncthing (no systemctl available)"
            track_skipped "Syncthing (no systemctl)"
        fi
        return 0
    fi

    # Detect previous installs and wipe if not already managed by us.
    if ! _syncthing_wipe_existing; then
        track_skipped "Syncthing (declined wipe)"
        return 0
    fi

    # Install the binary
    if command_exists syncthing; then
        print_skip "syncthing binary"
        track_skipped "syncthing"
    else
        if _syncthing_install_binary; then
            print_success "syncthing installed"
            track_installed "Syncthing"
        else
            track_failed "Syncthing"
            return 1
        fi
    fi
}

configure_syncthing() {
    if [[ "$LIGHT_MODE" == true ]]; then
        return 0
    fi
    if _syncthing_should_skip_platform; then
        return 0
    fi
    if ! command_exists syncthing; then
        return 0
    fi

    print_section "Syncthing Configuration"

    # Source ~/.env.sh so the user can keep the hub ID out of the repo.
    if [[ -f "$HOME/.env.sh" ]]; then
        # shellcheck disable=SC1091
        source "$HOME/.env.sh"
    fi

    local hub_id="${ZSH_SETUP_SYNCTHING_HUB_ID:-}"
    local hub_name="${ZSH_SETUP_SYNCTHING_HUB_NAME:-hub}"
    local device_name="${ZSH_SETUP_SYNCTHING_DEVICE_NAME:-$(hostname -s 2>/dev/null || hostname)}"
    local gui_address="${ZSH_SETUP_SYNCTHING_GUI_ADDRESS:-0.0.0.0:8384}"

    if [[ -z "$hub_id" ]]; then
        print_info "No ZSH_SETUP_SYNCTHING_HUB_ID set — skipping hub bootstrap"
        print_info "Add it to ~/.env.sh, then re-run install.sh to wire this host into the circle"
        track_skipped "Syncthing hub bootstrap (no ZSH_SETUP_SYNCTHING_HUB_ID)"
        return 0
    fi

    # Validate the hub ID shape (Syncthing IDs are 7×7 hex-ish blocks separated by dashes)
    if [[ ! "$hub_id" =~ ^[A-Z0-9]{7}(-[A-Z0-9]{7}){7}$ ]]; then
        print_warning "ZSH_SETUP_SYNCTHING_HUB_ID does not look like a valid device ID"
        print_info "Expected format: AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH"
        track_failed "Syncthing hub bootstrap (invalid hub ID)"
        return 1
    fi

    # First start: triggers config + key generation if config dir is empty
    if ! _syncthing_is_running; then
        if ! _syncthing_first_start; then
            track_failed "Syncthing service start"
            return 1
        fi
    fi

    # Read API key from generated config.xml
    local apikey
    apikey="$(_syncthing_apikey)"
    if [[ -z "$apikey" ]]; then
        print_error "Could not read Syncthing API key from config.xml"
        track_failed "Syncthing API key"
        return 1
    fi

    local my_id
    my_id="$(_syncthing_my_id "$apikey")"
    if [[ -z "$my_id" ]]; then
        print_error "Could not read this host's Syncthing device ID"
        track_failed "Syncthing device ID"
        return 1
    fi

    print_info "This host's device ID: $my_id"

    if _syncthing_set_device_name "$apikey" "$my_id" "$device_name"; then
        print_success "Set device name to '$device_name'"
    else
        print_warning "Could not set device name (continuing)"
    fi

    if _syncthing_add_hub_device "$apikey" "$hub_id" "$hub_name"; then
        print_success "Added hub '$hub_name' as introducer device"
        track_installed "Syncthing hub link"
    else
        print_error "Failed to add hub device via API"
        track_failed "Syncthing hub link"
        return 1
    fi

    # Bind the GUI to all interfaces (LAN/Tailscale reachable) and lock it
    # behind a generated user/password so Syncthing doesn't refuse non-loopback
    # access.
    _syncthing_load_or_make_creds
    if _syncthing_apply_gui_config "$apikey" "$gui_address" \
            "$SYNCTHING_GUI_USER" "$SYNCTHING_GUI_PASSWORD"; then
        print_success "GUI bound to $gui_address (auth as '$SYNCTHING_GUI_USER')"
        track_installed "Syncthing GUI ($gui_address)"
    else
        print_warning "Could not configure GUI bind address — leaving Syncthing default (loopback only)"
    fi

    _syncthing_write_marker

    echo ""
    print_info "Local Web UI : http://${SYNCTHING_API_HOST}/"
    print_info "Network UI   : http://<this-host>:${gui_address##*:}/"
    print_info "GUI user     : $SYNCTHING_GUI_USER"
    print_info "GUI password : $SYNCTHING_GUI_PASSWORD"
    print_info "  (also stored at $(_syncthing_creds_file))"
    echo ""
    print_info "Now go to the hub's Syncthing UI and accept '$device_name' under Pending Devices."
    print_info "The hub's existing folders will be offered to this host automatically."
}
