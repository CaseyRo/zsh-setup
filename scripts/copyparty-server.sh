#!/bin/bash
# ============================================================================
# Copyparty Home Server
# ============================================================================
# Starts copyparty sharing your home folder via HTTP and WebDAV.
#
# Usage:
#   ./scripts/copyparty-server.sh              # Start server
#   ./scripts/copyparty-server.sh --install    # Install as PM2 service
#   ./scripts/copyparty-server.sh --uninstall  # Remove PM2 service
#   ./scripts/copyparty-server.sh --status     # Check service status
#   ./scripts/copyparty-server.sh --reset-password  # Force new password
#
# Environment variables:
#   COPYPARTY_PORT      - HTTP/WebDAV port (default: 3923)
#   COPYPARTY_USER      - Username (default: current user)
#   COPYPARTY_FOLDER    - Folder to share (default: $HOME)
#   COPYPARTY_VERBOSE   - Enable verbose logging (true/false)
# ============================================================================

set -e

# Constants
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/copyparty"
CREDENTIALS_FILE="$CONFIG_DIR/credentials"
PASSWORD_EXPIRY_DAYS=60
SERVICE_NAME="copyparty-home"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_verbose() {
    [[ "$VERBOSE" == "true" ]] && echo -e "${GRAY}[debug]${NC} $*" >&2
}

# Check if copyparty is installed
check_copyparty() {
    log_verbose "Checking for copyparty binary"
    if ! command -v copyparty &>/dev/null; then
        echo -e "${RED}[error]${NC} Copyparty not installed."
        echo "        Install with: pip install copyparty"
        echo "        Or run: ./install.sh"
        exit 1
    fi
}

# Get or generate password with expiry
get_password() {
    local force_new="${1:-false}"

    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    # Check if we need a new password
    local need_new_password=true

    if [[ "$force_new" != "true" && -f "$CREDENTIALS_FILE" ]]; then
        # Read existing credentials
        source "$CREDENTIALS_FILE"

        if [[ -n "$COPYPARTY_PASSWORD" && -n "$COPYPARTY_CREATED" ]]; then
            # Check expiry
            local now
            now=$(date +%s)
            local expiry=$((COPYPARTY_CREATED + PASSWORD_EXPIRY_DAYS * 24 * 60 * 60))

            if [[ $now -lt $expiry ]]; then
                need_new_password=false
                PASSWORD="$COPYPARTY_PASSWORD"
                local days_left=$(( (expiry - now) / 86400 ))
                echo -e "${GRAY}[info]${NC} Using stored password (expires in ${days_left} days)" >&2
            else
                echo -e "${YELLOW}[info]${NC} Password expired, generating new one" >&2
            fi
        fi
    fi

    if [[ "$need_new_password" == "true" ]]; then
        log_verbose "Generating new copyparty password"
        PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
        local now
        now=$(date +%s)

        cat > "$CREDENTIALS_FILE" << EOF
# Copyparty credentials - auto-generated
# Created: $(date -Iseconds)
COPYPARTY_PASSWORD="$PASSWORD"
COPYPARTY_CREATED=$now
EOF
        chmod 600 "$CREDENTIALS_FILE"
        echo -e "${GREEN}[info]${NC} Generated new password (valid for ${PASSWORD_EXPIRY_DAYS} days)" >&2
    fi

    echo "$PASSWORD"
}

# Install as PM2 service
install_service() {
    check_copyparty

    if ! command -v pm2 &>/dev/null; then
        echo -e "${RED}[error]${NC} PM2 not installed."
        echo "        Install with: npm install -g pm2"
        exit 1
    fi

    # Get configuration
    local user_name="${COPYPARTY_USER:-${USER:-$(whoami)}}"
    local password
    password=$(get_password)
    local folder="${COPYPARTY_FOLDER:-$HOME}"
    local port="${COPYPARTY_PORT:-3923}"
    local copyparty_bin
    copyparty_bin=$(command -v copyparty)
    log_verbose "Installing PM2 service with user=$user_name folder=$folder port=$port"

    # Stop existing service if running
    pm2 delete "$SERVICE_NAME" 2>/dev/null || true

    # Start with PM2
    pm2 start "$copyparty_bin" --name "$SERVICE_NAME" -- \
        -q \
        -a "$user_name:$password" \
        -v "$folder:files:A,$user_name" \
        -p "$port"

    # Save PM2 config
    pm2 save

    echo ""
    echo -e "${GREEN}[success]${NC} Copyparty installed as PM2 service"
    echo ""
    echo -e "  ${BOLD}Credentials:${NC}"
    echo -e "    User:     ${YELLOW}$user_name${NC}"
    echo -e "    Password: ${YELLOW}$password${NC}"
    echo ""
    echo -e "  ${BOLD}Access:${NC}"
    echo -e "    Web/WebDAV: ${GREEN}http://localhost:$port/files${NC}"
    echo ""
    echo -e "  ${BOLD}Management:${NC}"
    echo -e "    Status:  pm2 status $SERVICE_NAME"
    echo -e "    Logs:    pm2 logs $SERVICE_NAME"
    echo -e "    Stop:    pm2 stop $SERVICE_NAME"
    echo -e "    Restart: pm2 restart $SERVICE_NAME"
    echo ""
    echo -e "  ${GRAY}To start on boot: pm2 startup${NC}"
}

# Uninstall PM2 service
uninstall_service() {
    if ! command -v pm2 &>/dev/null; then
        echo -e "${RED}[error]${NC} PM2 not installed."
        exit 1
    fi

    pm2 delete "$SERVICE_NAME" 2>/dev/null && \
        echo -e "${GREEN}[success]${NC} Service removed" || \
        echo -e "${YELLOW}[info]${NC} Service was not running"

    pm2 save
}

# Show service status
show_status() {
    if ! command -v pm2 &>/dev/null; then
        echo -e "${RED}[error]${NC} PM2 not installed."
        exit 1
    fi

    log_verbose "Checking PM2 service status for ${SERVICE_NAME}"
    pm2 describe "$SERVICE_NAME" 2>/dev/null || \
        echo -e "${YELLOW}[info]${NC} Service is not installed. Run with --install to set up."
}

# Run server interactively
run_server() {
    check_copyparty

    # Configuration
    local user_name="${COPYPARTY_USER:-${USER:-$(whoami)}}"
    local password
    password=$(get_password "$RESET_PASSWORD")
    local folder="${COPYPARTY_FOLDER:-$HOME}"
    local port="${COPYPARTY_PORT:-3923}"

    # Get Tailscale IP for network access (preferred), fallback to local IP
    local local_ip=""
    # Try Tailscale first (check both PATH and macOS app location)
    if command -v tailscale &>/dev/null; then
        log_verbose "Checking Tailscale IP via PATH"
        local_ip=$(tailscale ip -4 2>/dev/null || true)
    fi
    if [[ -z "$local_ip" && -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
        log_verbose "Checking Tailscale IP via macOS app bundle"
        local_ip=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4 2>/dev/null || true)
    fi

    # Fallback to local network IP if Tailscale not available
    if [[ -z "$local_ip" ]]; then
        log_verbose "Falling back to local network IP detection"
        if [[ "$(uname)" == "Darwin" ]]; then
            local_ip=$(ipconfig getifaddr en0 2>/dev/null)
            [[ -z "$local_ip" ]] && local_ip=$(ipconfig getifaddr en1 2>/dev/null)
            [[ -z "$local_ip" ]] && local_ip=$(route get default 2>/dev/null | awk '/interface:/ {iface=$2} END {if(iface) system("ipconfig getifaddr " iface)}' || true)
        else
            local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
            [[ -z "$local_ip" ]] && local_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || true)
        fi
    fi
    [[ -z "$local_ip" ]] && local_ip="<your-ip>"

    # Display banner
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Copyparty Home Server${NC}                                       ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Credentials:${NC}                                                ${CYAN}║${NC}"
    printf "${CYAN}║${NC}    User:      ${YELLOW}%-46s${NC} ${CYAN}║${NC}\n" "$user_name"
    printf "${CYAN}║${NC}    Password:  ${YELLOW}%-46s${NC} ${CYAN}║${NC}\n" "$password"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Sharing:${NC}                                                    ${CYAN}║${NC}"
    printf "${CYAN}║${NC}    Folder:    %-47s ${CYAN}║${NC}\n" "$folder"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Access URLs:${NC}                                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GRAY}Local:${NC}                                                      ${CYAN}║${NC}"
    printf "${CYAN}║${NC}    Web:       ${GREEN}%-47s${NC} ${CYAN}║${NC}\n" "http://localhost:$port"
    printf "${CYAN}║${NC}    WebDAV:    ${GREEN}%-47s${NC} ${CYAN}║${NC}\n" "http://localhost:$port/files"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GRAY}Network:${NC}                                                    ${CYAN}║${NC}"
    printf "${CYAN}║${NC}    Web:       ${GREEN}%-47s${NC} ${CYAN}║${NC}\n" "http://$local_ip:$port"
    printf "${CYAN}║${NC}    WebDAV:    ${GREEN}%-47s${NC} ${CYAN}║${NC}\n" "http://$local_ip:$port/files"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Connect from:${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}    macOS:   Finder > Cmd+K > http://$local_ip:$port/files     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}    Windows: Map Network Drive > http://$local_ip:$port/files  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}    Linux:   Files > dav://$local_ip:$port/files               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GRAY}Press Ctrl+C to stop the server${NC}"
    echo -e "${GRAY}Run with --install to set up as a background service${NC}"
    echo ""

    # Get full path to copyparty
    local copyparty_bin
    copyparty_bin=$(command -v copyparty)

    # Run copyparty
    log_verbose "Starting copyparty on port $port with folder $folder"
    "$copyparty_bin" \
        -q \
        -a "$user_name:$password" \
        -v "$folder:files:A,$user_name" \
        -p "$port"
}

# Parse arguments
RESET_PASSWORD="false"
VERBOSE="${COPYPARTY_VERBOSE:-false}"

case "${1:-}" in
    --install|-i)
        install_service
        ;;
    --uninstall|-u)
        uninstall_service
        ;;
    --status|-s)
        show_status
        ;;
    --reset-password|-r)
        RESET_PASSWORD="true"
        run_server
        ;;
    --verbose|-v)
        VERBOSE="true"
        run_server
        ;;
    --help|-h)
        echo "Copyparty Home Server"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (none)            Start server interactively"
        echo "  --install, -i     Install as PM2 background service"
        echo "  --uninstall, -u   Remove PM2 service"
        echo "  --status, -s      Check service status"
        echo "  --reset-password, -r  Force generate new password"
        echo "  --verbose, -v     Enable verbose logging"
        echo "  --help, -h        Show this help"
        echo ""
        echo "Environment variables:"
        echo "  COPYPARTY_PORT    HTTP/WebDAV port (default: 3923)"
        echo "  COPYPARTY_USER    Username (default: current user)"
        echo "  COPYPARTY_FOLDER  Folder to share (default: \$HOME)"
        echo "  COPYPARTY_VERBOSE Enable verbose logging (true/false)"
        ;;
    "")
        run_server
        ;;
    *)
        echo -e "${RED}[error]${NC} Unknown option: $1"
        echo "Run with --help for usage information"
        exit 1
        ;;
esac
