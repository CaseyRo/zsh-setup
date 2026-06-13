# ============================================================================
# cmux-setup — cmux workspace bootstrapper
# https://github.com/CaseyRo/cmux-setup
# ============================================================================

_cmux_setup_dir="$HOME/dev/cmux-setup"

# Clone on first load — must never block login or prompt for credentials.
# GIT_TERMINAL_PROMPT=0 makes git fail fast instead of hanging on a credential
# prompt (git writes that prompt to /dev/tty, so 2>/dev/null can't hide it);
# the low-speed timeout guards against a dead network; running it backgrounded
# means a slow clone never delays the prompt. Picks up next login if it fails.
if [[ ! -d "$_cmux_setup_dir" ]]; then
    (
        GIT_TERMINAL_PROMPT=0 git \
            -c credential.helper= \
            -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=10 \
            clone --depth 1 https://github.com/CaseyRo/cmux-setup.git "$_cmux_setup_dir"
    ) &>/dev/null &
fi

# Alias
if [[ -x "$_cmux_setup_dir/cmux-setup.sh" ]]; then
    # shellcheck disable=SC2139  # intentional: capture path at definition time
    alias cms="bash $_cmux_setup_dir/cmux-setup.sh"
fi

# Zsh completions
if [[ -d "$_cmux_setup_dir/completions" ]]; then
    # shellcheck disable=SC2206  # zsh fpath array append
    fpath=("$_cmux_setup_dir/completions" $fpath)
fi

unset _cmux_setup_dir
