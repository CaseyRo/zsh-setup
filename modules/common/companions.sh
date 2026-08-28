# ============================================================================
# Companion entrypoints (Claude Code Remote Control sessions)
# ============================================================================
# One shell function per companion in ~/dev/companion. Each opens a Remote
# Control session with a deterministic name, <companion>-<host>, so a session
# on another machine can find this one by name (ListAgents / SendMessage)
# instead of by a hand-shared session link. Separator is "-", not "@":
# SendMessage parses "@" as a teammate address and refuses the name. The contract is declared in
# ~/dev/companion/companions/<slug>/config.md → Hosts; this file only implements
# it. Nothing here starts a companion on its own — no timer, watcher, or hook.
#
#   ccc    companion-casey      casey-<host>
#   ccy    companion-yorizon    yorizon-<host>
#   ccsk   companion-storykeep  storykeep-<host>
#   ccben  companion-fitness    fitness-<host>   (Ben)
#
# Functions, not zsh-abbr abbreviations: they need no ZLE, so they work in Warp
# too without a mirror list in warp.sh. Extra arguments are passed to claude
# before the prompt, e.g. `ccc --effort max`.
#
# The host label mirrors /host-inventory: LocalHostName on macOS (cc1,
# caseys-air, NB-Romkes-1-A), `hostname -s` elsewhere.

_cc_companion() {
    local slug="$1" host
    shift
    host=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
    # Subshell: the session runs in ~/dev (where the companion skills resolve
    # and `claude remote-control -c` reattaches) without moving the caller's cwd.
    (
        cd "$HOME/dev" || return 1
        claude --remote-control "${slug}-${host}" -n "${slug}-${host}" \
            --permission-mode auto "$@" "/companion-${slug}"
    )
}

if command -v claude >/dev/null 2>&1; then
    ccc()   { _cc_companion casey "$@"; }
    ccy()   { _cc_companion yorizon "$@"; }
    ccsk()  { _cc_companion storykeep "$@"; }
    ccben() { _cc_companion fitness "$@"; }
fi
