# Claude Code — inject the Stolperfalle hook credentials from 1Password at launch.
# The stolperfalle plugin's error-recall hooks read these two vars and exit silently without
# them (found unset on cc1, 2026-09-28). Same pattern as hassio.sh. If op is locked or missing,
# claude still starts; recall just stays off.
claude() {
  # Tailnet, not the public origin: mcp-*.cdit-dev.de sits behind Cloudflare Access (CDI-1717).
  MCP_STOLPERFALLE_PUBLIC_URL="http://100.89.96.56:8716" \
  MCP_STOLPERFALLE_API_KEY="$(op read 'op://terminal access/2sbzzz2lp7v5hlrig6xqnr3tlq/API key' 2>/dev/null)" \
    command claude "$@"
}
