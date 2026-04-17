#!/bin/bash
# ============================================================================
#
#   ███████╗███████╗██╗  ██╗      ███████╗███████╗████████╗██╗   ██╗██████╗
#   ╚══███╔╝██╔════╝██║  ██║      ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
#     ███╔╝ ███████╗███████║█████╗███████╗█████╗     ██║   ██║   ██║██████╔╝
#    ███╔╝  ╚════██║██╔══██║╚════╝╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
#   ███████╗███████║██║  ██║      ███████║███████╗   ██║   ╚██████╔╝██║
#   ╚══════╝╚══════╝╚═╝  ╚═╝      ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
#
#   ZSH-Setup Setup Script
#   https://github.com/CaseyRo/zsh-setup
#
#   Usage: ./install.sh [OPTIONS]
#
#   Options:
#     -v, --verbose    Show detailed output from all commands
#     -h, --help       Show this help message
#
# ============================================================================

set -e

# ============================================================================
# Root/Sudo Check - Prevent running entire script as root
# ============================================================================

if [[ $EUID -eq 0 ]]; then
    # Allow running as root inside Docker containers
    if [[ -f /.dockerenv ]] || grep -qw docker /proc/1/cgroup 2>/dev/null || \
       grep -qw docker /proc/self/mountinfo 2>/dev/null; then
        # In Docker: define sudo as a passthrough (already root)
        sudo() { "$@"; }
        export -f sudo
        # Auto-enable non-interactive mode in Docker
        export YES_TO_ALL=true
    else
        echo ""
        echo "WARNING: Running as root is not recommended."
        echo "The installer needs a regular user account to set up dotfiles correctly."
        echo ""
        echo "Options:"
        echo "  1) Create a new user and continue as that user"
        echo "  2) Exit and re-run as a regular user"
        echo ""
        printf "Choose [1/2]: "
        read -r ROOT_CHOICE

        if [[ "$ROOT_CHOICE" == "1" ]]; then
            printf "Enter username to create: "
            read -r NEW_USERNAME

            if [[ -z "$NEW_USERNAME" ]]; then
                echo "ERROR: Username cannot be empty."
                exit 1
            fi

            # Validate username (lowercase, alphanumeric, hyphens, underscores)
            if [[ ! "$NEW_USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
                echo "ERROR: Invalid username. Use lowercase letters, numbers, hyphens, underscores."
                echo "       Must start with a letter."
                exit 1
            fi

            if id "$NEW_USERNAME" &>/dev/null; then
                echo "User '$NEW_USERNAME' already exists. Switching to that user..."
            else
                echo "Creating user '$NEW_USERNAME'..."

                if command -v useradd &>/dev/null; then
                    useradd -m -s /bin/bash "$NEW_USERNAME"
                elif command -v adduser &>/dev/null; then
                    adduser --disabled-password --gecos "" "$NEW_USERNAME"
                else
                    echo "ERROR: Cannot create user (no useradd or adduser found)."
                    exit 1
                fi

                # Set a password
                echo "Set a password for '$NEW_USERNAME':"
                passwd "$NEW_USERNAME"

                # Grant sudo access
                if command -v usermod &>/dev/null; then
                    if getent group sudo &>/dev/null; then
                        usermod -aG sudo "$NEW_USERNAME"
                    elif getent group wheel &>/dev/null; then
                        usermod -aG wheel "$NEW_USERNAME"
                    fi
                fi

                echo ""
                echo "User '$NEW_USERNAME' created with sudo access."
            fi

            # Ensure the new user can access the script directory
            SCRIPT_DIR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            NEW_HOME="$(eval echo "~$NEW_USERNAME")"

            # If the script is in /root, copy it to the new user's home
            if [[ "$SCRIPT_DIR_ROOT" == /root* ]]; then
                TARGET_DIR="$NEW_HOME/.zsh-setup"
                echo "Copying zsh-setup to $TARGET_DIR..."
                cp -r "$SCRIPT_DIR_ROOT" "$TARGET_DIR"
                chown -R "$NEW_USERNAME":"$NEW_USERNAME" "$TARGET_DIR"
                SCRIPT_DIR_ROOT="$TARGET_DIR"
            else
                # Make sure the user can read the script directory
                chmod -R o+rX "$SCRIPT_DIR_ROOT" 2>/dev/null || true
            fi

            echo ""
            echo "Re-running installer as '$NEW_USERNAME'..."
            echo ""
            exec su - "$NEW_USERNAME" -c "cd '$SCRIPT_DIR_ROOT' && bash ./install.sh $*"
        else
            echo ""
            echo "Re-run as a regular user:"
            echo "  ./install.sh"
            exit 1
        fi
    fi
fi

# ============================================================================
# Delegate to install/core.sh for arg parsing, sourcing, and main() dispatch.
# Root-check above must stay in this entrypoint because it re-execs as a new
# user; everything below is pure orchestration.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install/core.sh
source "$SCRIPT_DIR/install/core.sh"
main "$@"
