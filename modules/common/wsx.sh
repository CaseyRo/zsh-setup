# ============================================================================
# wsx / cmux-setup — workspace bootstrapper
# https://github.com/CaseyRo/wsx
#
# `wsx` is the primary tool (Warp adapter: catalog -> Warp Tab Configs + a
# launcher CLI). `cmux-setup.sh` is the legacy cmux adapter, kept as `cms`.
# The repo's completions/ dir (added to fpath below) carries both _wsx and
# _cmux-setup, so completion for either is auto-discovered by compinit.
# ============================================================================

_wsx_dir="$HOME/dev/wsx"

# Clone on first load — must never block login or prompt for credentials.
# GIT_TERMINAL_PROMPT=0 makes git fail fast instead of hanging on a credential
# prompt (git writes that prompt to /dev/tty, so 2>/dev/null can't hide it);
# the low-speed timeout guards against a dead network; running it backgrounded
# means a slow clone never delays the prompt. Picks up next login if it fails.
if [[ ! -d "$_wsx_dir" ]]; then
    (
        GIT_TERMINAL_PROMPT=0 git \
            -c credential.helper= \
            -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=10 \
            clone --depth 1 https://github.com/CaseyRo/wsx.git "$_wsx_dir"
    ) &>/dev/null &
fi

# wsx (primary, Warp): expose the repo dir on PATH so `wsx` is a real command
# (keeps its `#compdef wsx` completion working) — first run: `wsx setup`.
if [[ -x "$_wsx_dir/wsx" ]]; then
    # shellcheck disable=SC2206  # zsh path array prepend
    path=("$_wsx_dir" $path)
fi

# cms (legacy, cmux): the frozen cmux adapter kept under its old name.
if [[ -x "$_wsx_dir/cmux-setup.sh" ]]; then
    # shellcheck disable=SC2139  # intentional: capture path at definition time
    alias cms="bash $_wsx_dir/cmux-setup.sh"
fi

# Zsh completions for both wsx and cmux-setup.
if [[ -d "$_wsx_dir/completions" ]]; then
    # shellcheck disable=SC2206  # zsh fpath array append
    fpath=("$_wsx_dir/completions" $fpath)
fi

unset _wsx_dir
