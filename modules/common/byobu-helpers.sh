# ============================================================================
# Byobu session helpers — pair with cmux-setup remote workspaces
# ============================================================================
# Background: cmux 0.64.x doesn't deliver Enter to cmux-ssh workspace surfaces
# via `cmux send`, so cmux-setup's byobu auto-launch in the SSH path was
# dropped (cmux-setup commit 4cc31ed). Until that's fixed upstream, the user
# manually attaches to the right byobu session on the remote host after the
# workspace lands.
#
# These helpers exist so that step is a 2-keystroke command, not a 70-char
# byobu invocation. They live in modules/common so every machine reachable
# via SSH (notably cc1) gets them after a normal zsh-setup install.
#
# Conventions match cmux-setup's session naming:
#   project-N workspace  → pane 1: project<N>-1, pane 2: project<N>-2
#   storykeep-N workspace → pane 1: storykeep<N>-1, pane 2: storykeep<N>-2
# ============================================================================

# pj N [pane]  →  cd ~/dev then attach/create byobu session "project<N>-<pane>"
#                 pane defaults to 1.
# Examples:
#   pj 1     # project-1 pane 1   →  project1-1
#   pj 1 2   # project-1 pane 2   →  project1-2
#   pj 3     # project-3 pane 1   →  project3-1
pj() {
    if [[ -z "${1:-}" ]]; then
        echo "usage: pj <workspace-number> [pane-suffix]" >&2
        echo "  e.g. pj 1      → attach project1-1" >&2
        echo "       pj 1 2    → attach project1-2" >&2
        return 1
    fi
    local n="$1"
    local p="${2:-1}"
    cd ~/dev && byobu new-session -A -s "project${n}-${p}"
}

# sk N [pane]  →  cd ~/dev/StoryKeep then attach/create "storykeep<N>-<pane>"
# Examples:
#   sk 1     # storykeep-1 pane 1
#   sk 1 2   # storykeep-1 pane 2
sk() {
    if [[ -z "${1:-}" ]]; then
        echo "usage: sk <workspace-number> [pane-suffix]" >&2
        echo "  e.g. sk 1      → attach storykeep1-1" >&2
        echo "       sk 1 2    → attach storykeep1-2" >&2
        return 1
    fi
    local n="$1"
    local p="${2:-1}"
    cd ~/dev/StoryKeep && byobu new-session -A -s "storykeep${n}-${p}"
}

# Bare attacher — pass an explicit session name. Useful when the naming
# convention doesn't fit (one-off sessions, monitoring boxes, etc.).
alias bya='byobu new-session -A -s'
