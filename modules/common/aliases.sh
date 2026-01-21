# ============================================================================
# Common Aliases
# ============================================================================
# Shared aliases for all systems

# Command replacements
# alias ls="eza -l"
alias cd="z"
alias cat="bat"
alias top="htop"
alias docker-compose="docker compose"
alias lzg="lazygit"

# Docker shortcuts
alias dcdcu="docker-compose down && docker-compose up -d"
alias dcdcur="docker-compose down && docker-compose pull && docker-compose up -d"

# git_confirmer shortcuts (friendly fallback if missing)
if command -v git_confirmer >/dev/null 2>&1; then
    alias gc="git_confirmer"
    alias gcs="git_confirmer --ship"
else
    gc() {
        echo "git_confirmer not found. Run \"$ZSH_SETUP_FOLDER/install.sh\" and opt in to enable gc."
        return 127
    }
    gcs() {
        echo "git_confirmer not found. Run \"$ZSH_SETUP_FOLDER/install.sh\" and opt in to enable gcs."
        return 127
    }
fi

# YouTube downloader
alias ytdlp="yt-dlp -f 'best[ext=mp4]' -o '%(title).100s.%(ext)s'"
