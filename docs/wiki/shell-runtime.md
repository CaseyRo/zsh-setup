# Shell runtime

## Purpose [coverage: high, 7 sources]

Everything an interactive shell loads at startup: environment, aliases,
functions, completions, and tool initialisation. `~/.zshrc` is a symlink into
this repository, so the loader in `.zshrc` runs on every new shell on every
machine.

This code is on the critical path of every terminal you open. It is the one
place in the repository where speed is a design constraint rather than a
preference.

## Architecture [coverage: high, 5 sources]

Two directories feed the loader, in this order:

1. `preload_configs/` sets up the environment: locale, `PATH`, shared aliases.
2. `modules/` uses that settled environment: tool initialisation, completions,
   functions.

Within each, the loader walks scope from general to specific: `common/`, then
`<os>/`, then `<os>/<subos>/`. The operating system folder is `macos`, `linux`,
or `windows`. On Linux the sub-scope is `ubuntu` or `raspberry-pi`, detected
from `/etc/os-release` combined with `uname -m` and the Raspberry Pi devicetree
model. New configuration belongs in the narrowest scope that applies.

`path.sh` is special: it is loaded explicitly before the main walk, once for
`common` and once for the operating system scope, then skipped during the walk.
`~/.env.sh`, which is gitignored and holds private environment values, loads
between the path files and the rest.

The walk uses a zsh glob with the `(N.)` qualifiers rather than piping `find`
through `sort`: the same lexicographic order, without a subprocess per folder.
Lexicographic order is the entire ordering mechanism, which is what makes
filenames load-bearing.

`include` is a small helper that sources a file only when it exists. Prefer it
over bare `source` in modules so an absent optional file cannot break shell
startup.

## Key Decisions [coverage: high, 5 sources]

**The `zz_` prefix is a tail-init contract.** Four modules must load after
everything else, each for a concrete reason:

- `zz_abbr.sh` needs the zsh-abbr plugin that `starship.sh` sources.
- `zz_atuin.sh` must follow fzf to win the `Ctrl+R` binding.
- `zz_completions.sh` must follow the plugins in `starship.sh` so that
  zsh-autocomplete owns `compinit`.
- `zz_zoxide.sh` must be strictly last, because it overrides `cd`.

Nothing may sort after `zz_zoxide.sh`.

**Completion initialisation is where the startup budget was won.**
zsh-autocomplete defers `compinit` to the first prompt and owns the dump file.
When a foreign `compinit` runs first, autocomplete deletes `~/.zcompdump` at the
first prompt and rebuilds it, so `compinit` runs twice and the cache is never
reused. As a plain `completions.sh` the file sorted third, before
`starship.sh` sorted ninth, so its guard could never see autocomplete's
`compdef` and always ran `compinit` itself. That cost roughly 700 milliseconds
on every shell. Renaming it to `zz_completions.sh` made the guard meaningful.

**`compinit -C` was considered and rejected.** Trusting the dump and skipping
the fpath scan saves roughly 20 more milliseconds, but a newly installed tool's
completions would then never appear until the dump was deleted by hand. That is
a silent failure which is hard to trace back to its cause, and it is not worth
20 milliseconds against a 700 millisecond win.

**A leading `#` disables a file or folder.** The loader's `case` guard skips
`#`-prefixed filenames, and `#`-prefixed folders are never in the traversal
list. This is how code is retired without being deleted, for example
`#nvm.sh` and `modules/#deprecated/`. The same prefix excludes those files from
the runtime shellcheck scope.

**Environment defaults are guarded twice: on the tool existing, and on the user
not having chosen already.** `preload_configs/common/env.sh` sets `EDITOR` and
`VISUAL` to `hx`, but only when `hx` is actually on `PATH` and only when
`EDITOR` is still empty. The first guard matters because not every machine gets
Helix: armv7 Raspberry Pi images have no prebuilt binary, and pointing `EDITOR`
at a missing command breaks `git commit`, `crontab -e`, and every other tool
that shells out to it. The second guard is what makes the load order pay off,
since `~/.env.sh` is sourced before this file and an `EDITOR` exported there
therefore wins. A default that cannot be overridden locally is a setting, not a
default.

**Terminal type is normalised at the top of the loader.** Ghostty advertises
`TERM=xterm-ghostty`, which most remote hosts and multiplexers do not have a
terminfo entry for, so the loader falls back to `xterm-256color` when the entry
is missing locally.

## Gotchas [coverage: high, 3 sources]

Ordering constraints live in filenames and fail quietly. A module that loads too
early usually still appears to work; it is just slower, or a cache is defeated,
or a keybinding went to the wrong owner. Nothing errors. When a module depends
on another, say so in its header comment, because the dependency is otherwise
invisible.

Adding a file that sorts after `zz_zoxide.sh` breaks the `cd` override with no
message.

Runtime shell code is checked by shellcheck in bash mode even though it is zsh.
Known-good zsh idioms need a scoped inline disable with a one-line
justification: dynamic `source` paths, zsh-magic variables such as `reply` and
`SAVEHIST`, `fpath=(...)` array assignment, and git's `@{upstream}` syntax.

`.zshrc` itself is excluded from shellcheck entirely. It uses `fpath+=`, the
`include` helper, and operating system branches that no shellcheck mode handles
cleanly.

## Sources [coverage: high]

- [.zshrc](../../.zshrc)
- [modules/common/zz_completions.sh](../../modules/common/zz_completions.sh)
- [modules/common/zz_zoxide.sh](../../modules/common/zz_zoxide.sh)
- [modules/common/zz_atuin.sh](../../modules/common/zz_atuin.sh)
- [modules/common/zz_abbr.sh](../../modules/common/zz_abbr.sh)
- [modules/common/starship.sh](../../modules/common/starship.sh)
- [modules/common/mise.sh](../../modules/common/mise.sh)
- [modules/common/wsx.sh](../../modules/common/wsx.sh)
- [preload_configs/common/path.sh](../../preload_configs/common/path.sh)
- [preload_configs/common/env.sh](../../preload_configs/common/env.sh)
- [CLAUDE.md](../../CLAUDE.md)
- [AGENTS.md](../../AGENTS.md)
