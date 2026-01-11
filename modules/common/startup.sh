# ============================================================================
# Startup Commands
# ============================================================================
# Commands to run when a new shell session starts

# Display system info (fastfetch is much faster than hyfetch/neofetch)
if command -v fastfetch &> /dev/null; then
    fastfetch
elif command -v hyfetch &> /dev/null; then
    hyfetch
fi
