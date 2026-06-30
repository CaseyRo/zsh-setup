# ============================================================================
# macOS PATH Configuration
# ============================================================================

# Guarantee the current zsh's standard functions dir is on fpath.
# `brew shellenv` (run in .zshenv) does `export FPATH`, so fpath leaks into
# every child process — incl. the long-lived cmux server. zsh's compiled-in
# fpath holds a *version-specific* Cellar/zsh/<ver>/share/zsh/functions, so
# when that server was started before a Homebrew zsh patch bump (e.g.
# 5.9 -> 5.9.1) it froze the old path; after the bump that dir is gone and
# every new pane inherits the dead entry, so compinit/add-zsh-hook/colors/...
# aren't found and plugins spew "function definition file not found".
# The Homebrew share/zsh/functions symlink is version-independent, so
# prepending it self-heals regardless of the stale inherited FPATH and
# survives future upgrades.
# ponytail: hardcoded Homebrew prefixes (no per-shell `brew --prefix` cost);
#           guard makes it a no-op on non-Homebrew setups.
for _zfndir in /opt/homebrew/share/zsh/functions /usr/local/share/zsh/functions; do
    # shellcheck disable=SC2206  # zsh fpath array prepend
    [[ -d "$_zfndir" ]] && fpath=("$_zfndir" $fpath)
done
unset _zfndir

if [[ -d "$HOME/homebrew/bin" ]]; then
    export PATH="$HOME/homebrew/bin:$PATH"
fi

export PATH=$HOME/ruby-2.7.2/bin:$PATH
