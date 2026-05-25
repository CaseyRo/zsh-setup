#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_TARGET="$HOME/.zshrc"

# Backup .zshrc if existing
if [ -f "$ZSHRC_TARGET" ] || [ -L "$ZSHRC_TARGET" ]; then
    mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.backup"
    echo "Save existing ~/.zshrc file as ~/.zshrc.backup for backup"
fi

# Create symlink
ln -s "$SCRIPT_DIR/.zshrc" "$ZSHRC_TARGET"
echo "New symlink: ~/.zshrc → $SCRIPT_DIR/.zshrc"

# Symlink tmux config
TMUX_TARGET="$HOME/.tmux.conf"
if [ -f "$TMUX_TARGET" ] || [ -L "$TMUX_TARGET" ]; then
    mv "$TMUX_TARGET" "$TMUX_TARGET.backup"
    echo "Save existing ~/.tmux.conf as ~/.tmux.conf.backup for backup"
fi
ln -s "$SCRIPT_DIR/configs/tmux.conf" "$TMUX_TARGET"
echo "New symlink: ~/.tmux.conf → $SCRIPT_DIR/configs/tmux.conf"
