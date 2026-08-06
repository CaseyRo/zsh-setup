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

# Editor — Helix when it's here, otherwise leave whatever the system picked.
# Guarded because armv7 Pis get no prebuilt hx (see install/helix.sh) and a
# dangling $EDITOR breaks git commit, crontab -e and friends. Respects an
# EDITOR already exported from ~/.env.sh, which loads before this file.
if [[ -z "${EDITOR:-}" ]] && command -v hx >/dev/null 2>&1; then
  export EDITOR=hx
  export VISUAL=hx
fi
