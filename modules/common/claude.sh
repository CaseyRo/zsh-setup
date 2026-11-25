# Claude Code — drop a session marker this shell inherited by accident.
#
# A Claude Code session marks its own child processes with CLAUDE_CODE_CHILD_SESSION,
# so a Claude it starts itself writes no transcript. herdr-core outlives the session
# that started it, so a core first started from inside a session launders that
# session's markers into every terminal it spawns from then on. Found on 20 Nov 2026:
# CLAUDE_CODE_CHILD_SESSION=1 in every Herdr pane (from a casey-os session two days
# earlier), so every session reported "Transcript saving is off — inherited
# CLAUDE_CODE_CHILD_SESSION marker" and --resume found nothing.
#
# An interactive shell is never a child session — a person typed in it. Claude's own
# Bash tool runs a non-interactive shell, which never reads .zshrc, so a genuinely
# nested session keeps its marker and still stays out of the transcript store.
# Forcing CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 instead would also make those
# nested sessions save, which is not what we want.
unset CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_CHILD_NOTES_DIR \
  CLAUDE_CODE_BRIDGE_SESSION_ID CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN

# Claude Code — inject the Stolperfalle hook credentials from 1Password at launch.
# The stolperfalle plugin's error-recall hooks read these two vars and exit silently without
# them (found unset on cc1, 2026-09-28). Same pattern as hassio.sh. If op is locked or missing,
# claude still starts; recall just stays off. An op with no account asks "add an account manually
# now? [Y/n]" on the tty and waits forever, whatever stdin is; on the Yorizon hub that held every
# Asana-started session before claude ran (COS-294, 25 Nov 2026). So read only when op has an
# account or a service account token; `op account list` never prompts.
claude() {
  local key=""
  if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" || -n "$(op account list 2>/dev/null </dev/null)" ]]; then
    key="$(op read 'op://terminal access/2sbzzz2lp7v5hlrig6xqnr3tlq/API key' 2>/dev/null </dev/null)"
  fi
  # Tailnet, not the public origin: mcp-*.cdit-dev.de sits behind Cloudflare Access (CDI-1717).
  MCP_STOLPERFALLE_PUBLIC_URL="http://100.89.96.56:8716" MCP_STOLPERFALLE_API_KEY="$key" \
    command claude "$@"
}
