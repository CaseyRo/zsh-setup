# shellcheck shell=bash
# ============================================================================
# Common Environment — locale, default PATH extensions, aliases that run
# everywhere. Loaded before modules/, so modules can rely on these.
# Previously lived in the tail of .zshrc; relocated so tail-init modules
# (zz_atuin, zz_zoxide) see a settled environment.
# ============================================================================

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ClipSSH — clipboard screenshot to remote host
export CLIPSSH_HOST=cc1
alias css='clipssh'

# Go binaries (go install puts binaries here)
export PATH="$HOME/go/bin:$PATH"
