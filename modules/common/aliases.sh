# ============================================================================
# Common Aliases
# ============================================================================
# Shared aliases for all systems

# Command replacements
# alias ls="eza -l"
# cd is handled by zoxide init --cmd cd in tools.sh (creates cd + cdi)

# bat: on Debian/Ubuntu it's installed as 'batcat' due to naming conflict
if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
    export MANPAGER="bat -plman"
    export BAT_THEME="${BAT_THEME:-TwoDark}"
elif command -v batcat >/dev/null 2>&1; then
    alias cat="batcat"
    alias bat="batcat"
    export MANPAGER="batcat -plman"
    export BAT_THEME="${BAT_THEME:-TwoDark}"
fi

# fd: on Debian/Ubuntu it's installed as 'fdfind' due to naming conflict
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    alias fd="fdfind"
fi

alias top="htop"
alias docker-compose="docker compose"
alias lzg="lazygit"

# moltbot/clawdbot aliases (future-proofed for rename)
if command -v moltbot >/dev/null 2>&1; then
    alias mb="moltbot"
    alias clawdbot="moltbot"
    alias mbg="moltbot gateway"
elif command -v clawdbot >/dev/null 2>&1; then
    alias mb="clawdbot"
    alias moltbot="clawdbot"
    alias mbg="clawdbot gateway"
fi

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
