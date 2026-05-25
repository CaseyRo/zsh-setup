# ============================================================================
# tmux session helpers — pair with cmux-setup remote workspaces
# ============================================================================
# These helpers exist so attaching to the right tmux session on a remote host
# is a 2-keystroke command, not a 70-char invocation. They live in
# modules/common so every machine reachable via SSH (notably cc1) gets them
# after a normal zsh-setup install.
#
# Conventions match cmux-setup's session naming:
#   project-N workspace  → pane 1: project<N>-1, pane 2: project<N>-2
#   storykeep-N workspace → pane 1: storykeep<N>-1, pane 2: storykeep<N>-2
# ============================================================================

# pj N [pane]  →  cd ~/dev then attach/create tmux session "project<N>-<pane>"
#                 pane defaults to 1.
# Examples:
#   pj 1     # project-1 pane 1   →  project1-1
#   pj 1 2   # project-1 pane 2   →  project1-2
#   pj 3     # project-3 pane 1   →  project3-1
# shellcheck disable=SC2164
pj() {
    if [[ -z "${1:-}" ]]; then
        echo "usage: pj <workspace-number> [pane-suffix]" >&2
        echo "  e.g. pj 1      → attach project1-1" >&2
        echo "       pj 1 2    → attach project1-2" >&2
        return 1
    fi
    local n="$1"
    local p="${2:-1}"
    cd ~/dev && tmux new-session -A -s "project${n}-${p}"
}

# sk N [pane]  →  cd ~/dev/StoryKeep then attach/create "storykeep<N>-<pane>"
# Examples:
#   sk 1     # storykeep-1 pane 1
#   sk 1 2   # storykeep-1 pane 2
# shellcheck disable=SC2164
sk() {
    if [[ -z "${1:-}" ]]; then
        echo "usage: sk <workspace-number> [pane-suffix]" >&2
        echo "  e.g. sk 1      → attach storykeep1-1" >&2
        echo "       sk 1 2    → attach storykeep1-2" >&2
        return 1
    fi
    local n="$1"
    local p="${2:-1}"
    cd ~/dev/StoryKeep && tmux new-session -A -s "storykeep${n}-${p}"
}

# Bare attacher — pass an explicit session name.
# shellcheck disable=SC2139
alias txa='tmux new-session -A -s'
