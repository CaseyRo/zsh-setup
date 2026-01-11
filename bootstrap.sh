#!/bin/bash
# ============================================================================
# ZSH-Manager Bootstrap Script
# ============================================================================
# One-liner installation:
#   curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-manager/main/bootstrap.sh | sh
# or:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-manager/main/bootstrap.sh)"
# ============================================================================

set -e

REPO_URL="https://github.com/CaseyRo/zsh-manager.git"
INSTALL_DIR="${ZSH_MANAGER_DIR:-$HOME/.zsh-manager}"

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

# Check for git
if ! command -v git &> /dev/null; then
    echo "  Error: git is required but not installed."
    exit 1
fi

# Clone or update repo
if [ -d "$INSTALL_DIR" ]; then
    echo "  → Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull --quiet
else
    echo "  → Cloning zsh-manager to $INSTALL_DIR..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

# Run the setup script
echo "  → Running setup..."
echo ""
cd "$INSTALL_DIR"
exec bash ./install-on-new-machine.sh
