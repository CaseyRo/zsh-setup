# ============================================================================
# cmux-setup — cmux workspace bootstrapper
# https://github.com/CaseyRo/cmux-setup
# ============================================================================

_cmux_setup_dir="$HOME/dev/cmux-setup"

# Clone or update on first load (quiet, background-safe)
if [[ ! -d "$_cmux_setup_dir" ]]; then
    git clone --depth 1 https://github.com/CaseyRo/cmux-setup.git "$_cmux_setup_dir" 2>/dev/null
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
