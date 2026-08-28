# Shell runtime

## Purpose [coverage: high, 8 sources]

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

## Key Decisions [coverage: high, 7 sources]

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

**The configuration updates itself, and the update is deliberately detached
from the shell that triggered it.** `modules/common/auto-update.sh` checks once
per day; when the interval has elapsed it forks a background subshell that
fetches, fast-forwards, and then runs `install/upgrade.sh` to pick up packages
added since the last pull. See [installer](installer.md) for what that script
does. Backgrounding is the point: the work is slow and network-bound, and no
prompt should wait on it. A lock file serialises the check across tabs opening
at once, and a failed fetch shortens the retry to an hour rather than burning
the whole day. `ZSH_SETUP_DISABLE_AUTOUPDATE=1` opts out.

**Companion entrypoints are plain functions that open a session with a
deterministic name.** `modules/common/companions.sh` defines `ccc`, `ccy`,
`ccsk`, and `ccben`, one per companion in `~/dev/companion`. Each opens a
Claude Code Remote Control session named `<companion>-<host>`, with the host
label taken from `LocalHostName` on macOS and `hostname -s` elsewhere, so a
session on another machine can find this one by name through `ListAgents` and
`SendMessage` instead of a hand-shared link. The contract is declared in the
companion repo under each `companions/<slug>/config.md` Hosts section; this
module only implements it, and nothing here starts a companion on its own.
They are functions rather than zsh-abbr abbreviations because functions need no
ZLE and therefore work in Warp without a mirror entry in `warp.sh`. The session
runs in a subshell that has changed into `~/dev`, where the companion skills
resolve, without moving the caller's working directory.

The separator is `-`, not `@`. The first version (2026-08-27) named sessions
`<companion>@<host>`; `ListAgents` listed them fine, but `SendMessage` parses
`@` as a teammate address and refused the name outright, so every companion
session was visible and unaddressable at the same time. Renamed on 2026-08-28,
with the same change made to the declared contract in the companion repo.

**Terminal type is normalised at the top of the loader.** Ghostty advertises
`TERM=xterm-ghostty`, which most remote hosts and multiplexers do not have a
terminfo entry for, so the loader falls back to `xterm-256color` when the entry
is missing locally.

## Gotchas [coverage: high, 5 sources]

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

**A backgrounded job still owns the terminal's input, and one that reads it
stops forever.** The self-update worker was spawned as `&>/dev/null &`, which
redirects output but leaves stdin on the terminal. `install/upgrade.sh` reaches
`brew install --cask`, which shells out to sudo for a password, so the
background job read the terminal, took a `SIGTTIN`, and stopped. A stopped
process never runs its `EXIT` trap, so it kept the update lock. Nothing could
reclaim it, because the lock recorded `$$`, which in zsh stays the interactive
shell even inside a subshell: the stale-lock check was asking whether that
terminal tab was still open, not whether an update was still running. The tab
was open, so the self-update stayed silently dead for as long as it lived. On
one machine that was twenty nine hours, with the repository still reporting
itself up to date because the last completed pull had been clean. Redirect
stdin from `/dev/null` on any background job, and when a lock is meant to
outlive the shell that took it, record the worker's own pid through
`sysparams[pid]` after `zmodload zsh/system`.

An alias ending in a flag that takes an optional value swallows the next
argument. `eza --icons` accepts an optional value, so `alias ls="eza --icons"`
turned `ls /tmp` into `eza --icons /tmp` and failed on an invalid value for
`--icons`. `ll` escaped only because `--git` happened to follow its `--icons`.
All three listing aliases now pin `--icons=auto`, so flag order cannot
reintroduce it.

`.zshrc` itself is excluded from shellcheck entirely. It uses `fpath+=`, the
`include` helper, and operating system branches that no shellcheck mode handles
cleanly.

## Sources [coverage: high]

- [.zshrc](../../.zshrc)
- [modules/common/zz_completions.sh](../../modules/common/zz_completions.sh)
- [modules/common/zz_zoxide.sh](../../modules/common/zz_zoxide.sh)
- [modules/common/zz_atuin.sh](../../modules/common/zz_atuin.sh)
- [modules/common/zz_abbr.sh](../../modules/common/zz_abbr.sh)
- [modules/common/auto-update.sh](../../modules/common/auto-update.sh)
- [modules/common/companions.sh](../../modules/common/companions.sh)
- [modules/common/aliases.sh](../../modules/common/aliases.sh)
- [modules/common/starship.sh](../../modules/common/starship.sh)
- [modules/common/mise.sh](../../modules/common/mise.sh)
- [modules/common/wsx.sh](../../modules/common/wsx.sh)
- [preload_configs/common/path.sh](../../preload_configs/common/path.sh)
- [preload_configs/common/env.sh](../../preload_configs/common/env.sh)
- [CLAUDE.md](../../CLAUDE.md)
- [AGENTS.md](../../AGENTS.md)
