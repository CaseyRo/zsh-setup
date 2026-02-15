# ============================================================================
# Startup Commands
# ============================================================================
# Commands to run when a new shell session starts

# Ensure toilet is available (install if missing, before we display anything)
if ! command -v toilet &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command -v brew &> /dev/null && brew install toilet &> /dev/null 2>&1
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null && sudo -n true &> /dev/null 2>&1; then
            sudo apt-get update -qq &> /dev/null 2>&1
            sudo apt-get install -y -qq toilet &> /dev/null 2>&1
        fi
    fi
fi

# Display system info (fastfetch is much faster than hyfetch/neofetch)
if command -v fastfetch &> /dev/null; then
    fastfetch
elif command -v hyfetch &> /dev/null; then
    hyfetch
fi

# Display hostname with toilet (ASCII art) — right after fastfetch
if command -v toilet &> /dev/null; then
    toilet -f standard -F gay "$(hostname)" 2>/dev/null || true
fi
