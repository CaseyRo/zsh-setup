# ============================================================================
# mise — runtime version manager (supersedes NVM)
# ============================================================================
# Activates mise so Node/Python/etc. auto-switch per directory based on
# mise.toml / .tool-versions / .node-version files. Replaces the old per-OS
# nvm.sh modules (now disabled as #nvm.sh).
#
# Guarded so shells on machines without mise still start cleanly. mise's chpwd
# hook coexists with zoxide (zz_zoxide.sh), which loads later.

if command -v mise >/dev/null 2>&1; then
    # shellcheck disable=SC1090  # dynamic activation script emitted by mise
    eval "$(mise activate zsh)"
fi
