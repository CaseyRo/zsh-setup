# ============================================================================
# ZSH-Setup: Syncthing helpers
# ============================================================================
# Convenience commands for the per-user Syncthing instance bootstrapped by
# install/syncthing.sh. All of these are no-ops if syncthing isn't installed.
# ============================================================================

_st_api_host() {
    echo "127.0.0.1:8384"
}

_st_config_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/Syncthing"
    elif [[ -d "$HOME/.local/state/syncthing" ]]; then
        echo "$HOME/.local/state/syncthing"
    else
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/syncthing"
    fi
}

_st_apikey() {
    local config_xml
    config_xml="$(_st_config_dir)/config.xml"
    [[ -f "$config_xml" ]] || return 1
    sed -n 's|.*<apikey>\(.*\)</apikey>.*|\1|p' "$config_xml" | head -n1
}

_st_curl() {
    local apikey
    apikey="$(_st_apikey)" || return 1
    [[ -n "$apikey" ]] || return 1
    curl -fsS --max-time 5 -H "X-API-Key: $apikey" "$@"
}

# Print this host's Syncthing device ID.
st-id() {
    if ! command -v syncthing >/dev/null 2>&1; then
        echo "[syncthing] not installed"
        return 1
    fi
    local response
    response=$(_st_curl "http://$(_st_api_host)/rest/system/status" 2>/dev/null) || {
        echo "[syncthing] not running (try: st-restart)"
        return 1
    }
    echo "$response" | sed -n 's|.*"myID": *"\([^"]*\)".*|\1|p' | head -n1
}

# Restart the Syncthing service for the current user.
st-restart() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew services restart syncthing
            return $?
        fi
        echo "[syncthing] brew not available — cannot restart service"
        return 1
    fi
    systemctl --user restart syncthing.service
}

# Open the Syncthing web UI in the default browser.
st-open() {
    local url
    url="http://$(_st_api_host)/"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 &
    else
        echo "$url"
    fi
}

# Concise status: device count, sync state, pending devices/folders.
st-status() {
    if ! command -v syncthing >/dev/null 2>&1; then
        echo "[syncthing] not installed"
        return 1
    fi

    local my_id
    my_id="$(st-id)" || return 1

    local devices folders pending_devs pending_folds
    devices=$(_st_curl "http://$(_st_api_host)/rest/config/devices" 2>/dev/null \
        | grep -c '"deviceID"')
    folders=$(_st_curl "http://$(_st_api_host)/rest/config/folders" 2>/dev/null \
        | grep -c '"id"')
    pending_devs=$(_st_curl "http://$(_st_api_host)/rest/cluster/pending/devices" 2>/dev/null \
        | grep -c '"deviceID"')
    pending_folds=$(_st_curl "http://$(_st_api_host)/rest/cluster/pending/folders" 2>/dev/null \
        | grep -c '"folderID"')

    echo "\033[1mSyncthing\033[0m"
    echo "  Device ID : $my_id"
    echo "  Devices   : $devices configured"
    echo "  Folders   : $folders configured"
    echo "  Pending   : $pending_devs device(s), $pending_folds folder(s)"
    echo "  Web UI    : http://$(_st_api_host)/"
}

# Show pending devices and folders (devices/folders waiting for accept).
st-pending() {
    if ! command -v syncthing >/dev/null 2>&1; then
        echo "[syncthing] not installed"
        return 1
    fi
    echo "\033[1mPending devices:\033[0m"
    _st_curl "http://$(_st_api_host)/rest/cluster/pending/devices" 2>/dev/null \
        || echo "  (none / API unreachable)"
    echo ""
    echo "\033[1mPending folders:\033[0m"
    _st_curl "http://$(_st_api_host)/rest/cluster/pending/folders" 2>/dev/null \
        || echo "  (none / API unreachable)"
}
