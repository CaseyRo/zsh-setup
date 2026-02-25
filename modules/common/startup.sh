# ============================================================================
# Startup Commands
# ============================================================================
# Commands to run when a new shell session starts.
# Never install packages here — that belongs in install.sh.

# Display system info (fastfetch is much faster than hyfetch/neofetch)
if command -v fastfetch &> /dev/null; then
    fastfetch
elif command -v hyfetch &> /dev/null; then
    hyfetch
fi

# Display hostname with toilet (ASCII art) — right after fastfetch
if command -v toilet &> /dev/null; then
    toilet -w "${COLUMNS:-80}" -F gay "$(hostname)" 2>/dev/null || true
fi
