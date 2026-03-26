#!/bin/sh
# ============================================================================
# ZSH-Setup Bootstrap Script
# ============================================================================
# One-liner installation (recommended):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-setup/main/bootstrap.sh)"
#
# Alternative (if bash is not available):
#   curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-setup/main/bootstrap.sh | sh
# ============================================================================

set -e

# Capture arguments to pass through to install.sh
INSTALL_ARGS="$*"

REPO_URL="https://github.com/CaseyRo/zsh-setup.git"

# ============================================================================
# Root Check - Create a user if running as root on a fresh machine
# ============================================================================

_is_docker() {
    [ -f /.dockerenv ] || grep -qw docker /proc/1/cgroup 2>/dev/null || \
       grep -qw docker /proc/self/mountinfo 2>/dev/null
}

if [ "$(id -u)" -eq 0 ] && ! _is_docker; then
    echo ""
    echo "  WARNING: Running as root is not recommended."
    echo "  The installer needs a regular user account to set up dotfiles correctly."
    echo ""
    echo "  Options:"
    echo "    1) Create a new user and continue as that user"
    echo "    2) Exit and re-run as a regular user"
    echo ""
    printf "  Choose [1/2]: "
    read -r ROOT_CHOICE

    if [ "$ROOT_CHOICE" = "1" ]; then
        printf "  Enter username to create: "
        read -r NEW_USERNAME

        if [ -z "$NEW_USERNAME" ]; then
            echo "  ERROR: Username cannot be empty."
            exit 1
        fi

        if id "$NEW_USERNAME" >/dev/null 2>&1; then
            echo "  User '$NEW_USERNAME' already exists. Switching to that user..."
        else
            echo "  Creating user '$NEW_USERNAME'..."

            if command -v useradd >/dev/null 2>&1; then
                useradd -m -s /bin/bash "$NEW_USERNAME"
            elif command -v adduser >/dev/null 2>&1; then
                adduser --disabled-password --gecos "" "$NEW_USERNAME"
            else
                echo "  ERROR: Cannot create user (no useradd or adduser found)."
                exit 1
            fi

            # Set a password
            echo "  Set a password for '$NEW_USERNAME':"
            passwd "$NEW_USERNAME"

            # Grant sudo access
            if command -v usermod >/dev/null 2>&1; then
                if getent group sudo >/dev/null 2>&1; then
                    usermod -aG sudo "$NEW_USERNAME"
                elif getent group wheel >/dev/null 2>&1; then
                    usermod -aG wheel "$NEW_USERNAME"
                fi
            fi

            # Install sudo if not present (common on minimal Debian)
            if ! command -v sudo >/dev/null 2>&1; then
                echo "  Installing sudo..."
                if command -v apt-get >/dev/null 2>&1; then
                    apt-get update -qq && apt-get install -y -qq sudo
                elif command -v dnf >/dev/null 2>&1; then
                    dnf install -y sudo
                fi
            fi

            echo ""
            echo "  User '$NEW_USERNAME' created with sudo access."
        fi

        # Install git if needed (as root, before switching)
        if ! command -v git >/dev/null 2>&1; then
            echo "  Installing git..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update -qq && apt-get install -y -qq git
            elif command -v dnf >/dev/null 2>&1; then
                dnf install -y git
            fi
        fi

        echo ""
        echo "  Re-running bootstrap as '$NEW_USERNAME'..."
        echo ""
        # Re-exec the bootstrap as the new user (they'll clone into their own home)
        exec su - "$NEW_USERNAME" -c "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-setup/main/bootstrap.sh)\" -- $INSTALL_ARGS"
    else
        echo ""
        echo "  Re-run as a regular user, or log in as one first."
        exit 1
    fi
fi

INSTALL_DIR="${ZSH_SETUP_DIR:-${ZSH_MANAGER_DIR:-$HOME/.zsh-setup}}"

echo ""
echo "  ███████╗███████╗██╗  ██╗      ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ "
echo "  ╚══███╔╝██╔════╝██║  ██║      ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗"
echo "    ███╔╝ ███████╗███████║█████╗██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝"
echo "   ███╔╝  ╚════██║██╔══██║╚════╝██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗"
echo "  ███████╗███████║██║  ██║      ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║"
echo "  ╚══════╝╚══════╝╚═╝  ╚═╝      ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝"
echo ""
echo "  Bootstrap Installer"
echo ""

# Check for git (POSIX-compatible check using 'command')
if ! command -v git >/dev/null 2>&1; then
    echo "  Error: git is required but not installed."
    echo ""
    echo "  Install git first:"
    echo "    macOS:  xcode-select --install"
    echo "    Ubuntu: sudo apt install git"
    echo "    Fedora: sudo dnf install git"
    exit 1
fi

# Clone or update repo
if [ -d "$INSTALL_DIR" ]; then
    echo "  → Updating existing installation..."
    cd "$INSTALL_DIR"
    # Stash local changes so pull isn't blocked
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        echo "  → Stashing local changes..."
        git stash push --quiet -m "bootstrap auto-stash $(date +%Y-%m-%d)"
    fi
    if ! git pull --ff-only --quiet; then
        echo "  ⚠ Pull failed (diverged history?). Trying reset to upstream..."
        git fetch --quiet
        git reset --hard origin/main --quiet
    fi
else
    echo "  → Cloning zsh-setup to $INSTALL_DIR..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

# Validate install.sh syntax before running
echo "  → Validating install scripts..."
if ! bash -n "$INSTALL_DIR/install.sh" 2>/dev/null; then
    echo "  ERROR: install.sh has syntax errors. Aborting."
    echo "  Try re-cloning: rm -rf $INSTALL_DIR && re-run bootstrap."
    exit 1
fi

# Run the setup script
echo "  → Running setup..."
echo ""
cd "$INSTALL_DIR"
exec bash ./install.sh $INSTALL_ARGS
