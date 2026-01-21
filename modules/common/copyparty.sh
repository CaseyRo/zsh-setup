# ============================================================================
# ZSH-Setup: Copyparty File Server
# ============================================================================
# Provides convenient functions to start copyparty as a local file server.
# https://github.com/9001/copyparty
# ============================================================================

# Start copyparty sharing home folder via SMB (read-write)
# Usage: copyparty-home [password]
#   If no password provided, generates a random one
copyparty-home() {
    if ! command -v copyparty &>/dev/null; then
        echo "\033[0;31m[copyparty]\033[0m Not installed. Run: uv tool install copyparty (or pipx/pip)"
        return 1
    fi

    local user="${USER:-$(whoami)}"
    local password="${1:-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)}"
    local home_dir="$HOME"
    local port="${COPYPARTY_PORT:-3923}"
    local smb_port="${COPYPARTY_SMB_PORT:-445}"

    echo ""
    echo "\033[0;36m┌─────────────────────────────────────────────────────────────┐\033[0m"
    echo "\033[0;36m│\033[0m  \033[1mCopyparty Home Share\033[0m                                       \033[0;36m│\033[0m"
    echo "\033[0;36m├─────────────────────────────────────────────────────────────┤\033[0m"
    echo "\033[0;36m│\033[0m  User:      \033[1;33m$user\033[0m"
    echo "\033[0;36m│\033[0m  Password:  \033[1;33m$password\033[0m"
    echo "\033[0;36m│\033[0m  Folder:    \033[0;37m$home_dir\033[0m"
    echo "\033[0;36m├─────────────────────────────────────────────────────────────┤\033[0m"
    echo "\033[0;36m│\033[0m  \033[1mAccess via:\033[0m"
    echo "\033[0;36m│\033[0m  Web:       \033[0;32mhttp://localhost:$port\033[0m"
    echo "\033[0;36m│\033[0m  SMB:       \033[0;32msmb://localhost:$smb_port/home\033[0m"
    echo "\033[0;36m│\033[0m  WebDAV:    \033[0;32mhttp://localhost:$port/home\033[0m"
    echo "\033[0;36m└─────────────────────────────────────────────────────────────┘\033[0m"
    echo ""
    echo "\033[0;90mPress Ctrl+C to stop the server\033[0m"
    echo ""

    # Check if SMB port requires sudo (ports < 1024)
    if [[ "$smb_port" -lt 1024 ]]; then
        echo "\033[0;33m[note]\033[0m SMB port $smb_port requires sudo"
        sudo copyparty \
            -a "$user:$password" \
            -v "$home_dir:home:A,$user" \
            -p "$port" \
            --smbw \
            --smb-port "$smb_port"
    else
        copyparty \
            -a "$user:$password" \
            -v "$home_dir:home:A,$user" \
            -p "$port" \
            --smbw \
            --smb-port "$smb_port"
    fi
}

# Start copyparty sharing a specific folder
# Usage: copyparty-share <folder> [password]
copyparty-share() {
    if ! command -v copyparty &>/dev/null; then
        echo "\033[0;31m[copyparty]\033[0m Not installed. Run: uv tool install copyparty (or pipx/pip)"
        return 1
    fi

    local folder="${1:-.}"
    local password="${2:-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)}"
    local user="${USER:-$(whoami)}"
    local port="${COPYPARTY_PORT:-3923}"

    # Resolve to absolute path
    folder="$(cd "$folder" 2>/dev/null && pwd)" || {
        echo "\033[0;31m[copyparty]\033[0m Folder not found: $1"
        return 1
    }

    local share_name="$(basename "$folder")"

    echo ""
    echo "\033[0;36m┌─────────────────────────────────────────────────────────────┐\033[0m"
    echo "\033[0;36m│\033[0m  \033[1mCopyparty Share\033[0m                                            \033[0;36m│\033[0m"
    echo "\033[0;36m├─────────────────────────────────────────────────────────────┤\033[0m"
    echo "\033[0;36m│\033[0m  User:      \033[1;33m$user\033[0m"
    echo "\033[0;36m│\033[0m  Password:  \033[1;33m$password\033[0m"
    echo "\033[0;36m│\033[0m  Folder:    \033[0;37m$folder\033[0m"
    echo "\033[0;36m├─────────────────────────────────────────────────────────────┤\033[0m"
    echo "\033[0;36m│\033[0m  \033[1mAccess via:\033[0m"
    echo "\033[0;36m│\033[0m  Web:       \033[0;32mhttp://localhost:$port\033[0m"
    echo "\033[0;36m│\033[0m  WebDAV:    \033[0;32mhttp://localhost:$port/$share_name\033[0m"
    echo "\033[0;36m└─────────────────────────────────────────────────────────────┘\033[0m"
    echo ""
    echo "\033[0;90mPress Ctrl+C to stop the server\033[0m"
    echo ""

    copyparty \
        -a "$user:$password" \
        -v "$folder:$share_name:A,$user" \
        -p "$port"
}

# Quick read-only share of current directory (no auth)
# Usage: copyparty-quick
copyparty-quick() {
    if ! command -v copyparty &>/dev/null; then
        echo "\033[0;31m[copyparty]\033[0m Not installed. Run: uv tool install copyparty (or pipx/pip)"
        return 1
    fi

    local port="${COPYPARTY_PORT:-3923}"

    echo ""
    echo "\033[0;32m[copyparty]\033[0m Sharing current directory (read-only, no auth)"
    echo "           Web: \033[0;36mhttp://localhost:$port\033[0m"
    echo ""

    copyparty -p "$port"
}
