#!/bin/bash
# ============================================================================
# Copyparty Home Server
# ============================================================================
# Starts copyparty sharing your home folder via HTTP, WebDAV, and SMB.
# Run with: ./scripts/copyparty-server.sh [password]
#
# Environment variables:
#   COPYPARTY_PORT      - HTTP/WebDAV port (default: 3923)
#   COPYPARTY_SMB_PORT  - SMB port (default: 3445, use 445 for standard)
#   COPYPARTY_USER      - Username (default: current user)
#   COPYPARTY_FOLDER    - Folder to share (default: $HOME)
# ============================================================================

set -e

# Check if copyparty is installed
if ! command -v copyparty &>/dev/null; then
    echo -e "\033[0;31m[error]\033[0m Copyparty not installed."
    echo "        Install with: pip install copyparty"
    echo "        Or run: ./install.sh"
    exit 1
fi

# Configuration
USER_NAME="${COPYPARTY_USER:-${USER:-$(whoami)}}"
PASSWORD="${1:-$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)}"
FOLDER="${COPYPARTY_FOLDER:-$HOME}"
PORT="${COPYPARTY_PORT:-3923}"
SMB_PORT="${COPYPARTY_SMB_PORT:-445}"

# Get local IP for network access info
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ipconfig getifaddr en0 2>/dev/null || echo "localhost")

# Display banner
echo ""
echo -e "\033[0;36m╔═══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[0;36m║\033[0m  \033[1m📁 Copyparty Home Server\033[0m                                     \033[0;36m║\033[0m"
echo -e "\033[0;36m╠═══════════════════════════════════════════════════════════════╣\033[0m"
echo -e "\033[0;36m║\033[0m                                                               \033[0;36m║\033[0m"
echo -e "\033[0;36m║\033[0m  \033[1mCredentials:\033[0m                                                \033[0;36m║\033[0m"
printf "\033[0;36m║\033[0m    User:      \033[1;33m%-46s\033[0m \033[0;36m║\033[0m\n" "$USER_NAME"
printf "\033[0;36m║\033[0m    Password:  \033[1;33m%-46s\033[0m \033[0;36m║\033[0m\n" "$PASSWORD"
echo -e "\033[0;36m║\033[0m                                                               \033[0;36m║\033[0m"
echo -e "\033[0;36m║\033[0m  \033[1mSharing:\033[0m                                                    \033[0;36m║\033[0m"
printf "\033[0;36m║\033[0m    Folder:    %-47s \033[0;36m║\033[0m\n" "$FOLDER"
echo -e "\033[0;36m║\033[0m                                                               \033[0;36m║\033[0m"
echo -e "\033[0;36m╠═══════════════════════════════════════════════════════════════╣\033[0m"
echo -e "\033[0;36m║\033[0m  \033[1mAccess URLs:\033[0m                                                \033[0;36m║\033[0m"
echo -e "\033[0;36m║\033[0m                                                               \033[0;36m║\033[0m"
echo -e "\033[0;36m║\033[0m  \033[0;90mLocal:\033[0m                                                      \033[0;36m║\033[0m"
printf "\033[0;36m║\033[0m    Web:     \033[0;32m%-49s\033[0m \033[0;36m║\033[0m\n" "http://localhost:$PORT"
printf "\033[0;36m║\033[0m    SMB:     \033[0;32m%-49s\033[0m \033[0;36m║\033[0m\n" "smb://localhost:$SMB_PORT/files"
echo -e "\033[0;36m║\033[0m                                                               \033[0;36m║\033[0m"
echo -e "\033[0;36m║\033[0m  \033[0;90mNetwork:\033[0m                                                    \033[0;36m║\033[0m"
printf "\033[0;36m║\033[0m    Web:     \033[0;32m%-49s\033[0m \033[0;36m║\033[0m\n" "http://$LOCAL_IP:$PORT"
printf "\033[0;36m║\033[0m    SMB:     \033[0;32m%-49s\033[0m \033[0;36m║\033[0m\n" "smb://$LOCAL_IP:$SMB_PORT/files"
echo -e "\033[0;36m║\033[0m                                                               \033[0;36m║\033[0m"
echo -e "\033[0;36m╚═══════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[0;90mPress Ctrl+C to stop the server\033[0m"
echo ""

# Get full path to copyparty (needed for sudo which doesn't preserve PATH)
COPYPARTY_BIN=$(command -v copyparty)

# Build copyparty command
COPYPARTY_CMD=(
    "$COPYPARTY_BIN"
    -q
    -a "$USER_NAME:$PASSWORD"
    -v "$FOLDER:files:A,$USER_NAME"
    -p "$PORT"
    --smbw
    --smb-port "$SMB_PORT"
)

# Check if SMB port requires sudo (ports < 1024)
if [[ "$SMB_PORT" -lt 1024 ]]; then
    echo -e "\033[0;33m[note]\033[0m SMB port $SMB_PORT requires elevated privileges"
    sudo "${COPYPARTY_CMD[@]}"
else
    "${COPYPARTY_CMD[@]}"
fi
