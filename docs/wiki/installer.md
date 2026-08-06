# Installer

## Purpose [coverage: high, 9 sources]

Provision a machine from a fresh operating system to a working environment, and
keep doing so safely on every later run. The installer is the only supported way
to set the machine up; there is no manual checklist it shadows.

Its value proposition is re-runnability. Every module checks whether its target
already exists and skips rather than erroring, which is why the smoke test runs
`install.sh` twice inside the same image and expects the second pass to be
clean. A module that cannot be run twice is a bug, not a rough edge.

## Architecture [coverage: high, 6 sources]

`install.sh` is deliberately thin: it performs the root check, sources
`install/core.sh`, and calls `main`. Everything else lives in `core.sh`, which
holds argument parsing, the explicit list of `source` lines for each installer
module, and the `main` dispatch order.

Installer modules are one file per installable concern, each exposing named
functions that `main` calls in order. The module list in `core.sh` is explicit
rather than a glob, so adding a module means adding both a `source` line and a
call site.

Package lists live in `install/packages.sh`, never inside the installer
modules. Arrays are grouped by package manager: `BREW_PACKAGES`,
`BREW_PACKAGES_MAC_DEV`, `BREW_CASKS`, `CARGO_PACKAGES`, `APT_PACKAGES`,
`GO_PACKAGES`, `NPM_GLOBAL_PACKAGES`, `MISE_TOOLS`, `DEV_REPOS`, `NERD_FONTS`,
`MAS_APPS`. Adding a tool is an edit to one array; the installer module that
consumes it does not change.

Platform detection is centralised in `install/utils.sh`: `is_macos`,
`is_ubuntu`, `is_debian`, `is_raspberry_pi`, `is_arm`, `is_docker`,
`should_use_apt`, `command_exists`. Modules call these rather than re-checking
`$OSTYPE` or parsing `/etc/os-release` themselves.

Output goes through the `print_*` and `track_*` helpers, never bare `echo`, so
every action lands in the run summary as installed, skipped, or failed.

## Key Decisions [coverage: high, 8 sources]

**Profiles are flags, not separate scripts.** `--light` (aliased `--server`,
`--vps`) targets minimal servers: it skips Rust toolchain builds and prefers
prebuilt binaries via `install/prebuilt-bins.sh`. `--dev` (aliased
`--mac-dev-machine`) turns on the macOS dev machine extras. The two conflict and
the parser rejects them together with an explicit error rather than letting one
silently win.

**Package-manager preference is a ladder, not a per-tool choice.** Cargo for
Rust tools, then Homebrew on macOS, then apt on Linux and ARM, with
`install/prebuilt-bins.sh` as the last resort where building Rust is too
expensive. This is why the same tool arrives by different routes on different
machines and why `--light` changes the answer.

**Choices persist in `.install-state`.** Dev machine profile, networked services
opt-in, and the Warp install decision are written to a gitignored state file at
the repository root and re-read on later runs, so an unattended re-run does not
re-prompt or silently reverse an earlier answer. Explicit command-line flags
always beat persisted state. The legacy `.prompt-choice` file is migrated
automatically on first sight.

**Runtime versions are managed by mise, not nvm.** `install/mise.sh` installs
mise and pins `node@lts`, then `mise_install_tools` pins everything listed in
`MISE_TOOLS`. Node stays out of that list on purpose: `mise_install_node` has to
reshim and push the shim directory onto `PATH` immediately afterwards so that
`install_npm_global_packages` can find `npm` in the same run. The old per-OS nvm
runtime modules are disabled with the `#` prefix, but `install/nvm.sh` is still
sourced because it defines `install_npm_global_packages`.

**Config files are seeded two different ways, and the difference is
load-bearing.** Files the owning tool never rewrites are symlinked into the
repository, so edits propagate both directions: `~/.zshrc`, `starship.toml`,
`topgrade.toml`, `tmux.conf`, and Helix's `config.toml` plus its Cobalt2 theme.
Files the owning tool rewrites at runtime are copied once and only when absent:
Warp's `settings.toml`, atuin's `config.toml`, and herdr's `config.toml`. A tool
that writes its config atomically replaces the file through a rename, which
silently swaps a symlink for a regular file and detaches it from the repository
without any error. Copy-if-absent also means an existing machine's local edits
are never clobbered. The test is not how important the file is, it is whether
the owning tool ever writes it back.

**A module failure must not end the run.** `install.sh` sets `set -e` and `main`
calls every module bare, so any module returning non-zero terminates the whole
install at that point. Everything after it is skipped silently, including the
`~/.zshrc` symlink and the run summary, which makes an ordinary optional-tool
failure look like a hard crash. Installer modules therefore return zero on
failure and report through `track_failed`, which surfaces the problem in the
summary without taking the run down. Reserve a non-zero return for a condition
that genuinely invalidates everything after it.

**Helix is installed differently per platform because no single route works.**
macOS takes the Homebrew bottle through `BREW_PACKAGES`. Linux cannot: Helix is
absent from the Ubuntu 22.04 and 24.04 and Raspberry Pi OS repositories, and
`cargo install helix-term` deliberately omits the runtime directory, which
leaves a binary with no grammars or queries. `install/helix.sh` therefore
fetches the official release tarball, which ships `hx` and `runtime/` together,
and lays it out as `/opt/helix/bin/hx` with `/opt/helix/runtime`. That layout is
chosen so the exe-relative lookup resolves: on Linux `current_exe` reads
`/proc/self/exe`, which is already symlink-resolved, so the `/usr/local/bin/hx`
symlink on `PATH` does not break discovery and no environment variable is
needed.

**Root is a fork in the road, not an error.** Running as root outside a
container starts an interactive new-user creation flow. Inside a container,
detected through `/.dockerenv` or the docker cgroup, the installer instead
enables `YES_TO_ALL` and stubs `sudo` as a passthrough so the smoke test can run
unattended.

## Gotchas [coverage: high, 8 sources]

A new installer module needs three edits, not one: the file itself, a `source`
line in `core.sh`, and a call inside `main`. Miss the call and the module is
dead code that shellcheck will still happily pass.

Placement inside `main` decides which machines get the module. The mise block
sits inside a branch that is skipped entirely when a container already provides
Node, so anything appended there silently never runs in that case. Anything
gated behind `LIGHT_MODE != true` will not reach servers.

`mise` installed through the official installer lands at `~/.local/bin/mise`,
which is not necessarily on the installer's own `PATH` yet. `_mise_bin`
resolves it; calling `mise` directly in a new module can work on your machine
and fail on a fresh one.

**Presence is not health, and a guard that confuses the two is worse than no
guard.** On Debian 12 and Raspberry Pi OS bookworm the official mise installer
produces a binary that exists but cannot execute, because it is a glibc build
newer than the system libc, so `_mise_works` tests execution rather than
presence and falls back to the static musl build. A Homebrew `composer` whose
phar signature no longer verifies behaves the same way: it satisfies
`command_exists`, then dies with an uncaught `PharException` partway through the
run, so `install_php_dev_tools` gates on `composer --version` actually
succeeding. An installed-but-dead binary must never satisfy a skip guard.

A Homebrew bottle can hardcode an absolute path that is wrong under a custom
prefix. The `helix` bottle bakes in `/opt/homebrew/.../libexec/runtime`, so on a
`$HOME/homebrew` prefix, which this repo explicitly supports, `hx` installs
cleanly and then loses highlighting, indent and textobjects for every language.
Nothing errors; the only symptom is a column of ✘ in `hx --health`.
`_link_helix_runtime` resolves the real directory through `brew --prefix` and
points `~/.config/helix/runtime`, Helix's highest-priority lookup, at it. It
links the version-stable `opt/` path rather than the versioned Cellar path so a
later `brew upgrade` does not strand it. Prefix-relative paths belong in the
installer, not in whatever the upstream package assumed.

Upstream package names drift, and a renamed package defeats both the install and
the skip guard. Homebrew renamed the `tailscale` cask to `tailscale-app`, freeing
the plain name for the CLI formula. Because that cask ships a `.pkg`, it leaves
nothing under `/Applications` and puts no `tailscale` on `PATH` until the menu
bar app is launched once, so neither the `command_exists` guard nor the
`/Applications/Tailscale.app` guard saw an install that was already present.
Ask the package manager directly with `brew list --cask` when the artifact
itself is not reliably discoverable. That cask also needs sudo, which `main` has
deliberately dropped through `sudo -k` before user-space installers run, so
failing under `--yes` with no terminal is expected rather than broken.

`getent` does not exist on macOS, and `cmd | cut ... || fallback` binds the
`||` to the pipeline's exit status, which is `cut`'s and therefore almost always
zero. `set_default_shell_zsh` combined both mistakes, so `current_shell` came
back empty on macOS, the already-zsh check never matched, and every run re-ran
`chsh` on a shell that was already correct. Look the shell up through `dscl` on
macOS, and never rely on `||` to catch a failure from anywhere but the last
command in a pipeline.

`VERSION` is written by a pre-commit hook from the commit count. Editing it by
hand produces a conflict on the next commit.

## Sources [coverage: high]

- [install.sh](../../install.sh)
- [install/core.sh](../../install/core.sh)
- [install/utils.sh](../../install/utils.sh)
- [install/packages.sh](../../install/packages.sh)
- [install/mise.sh](../../install/mise.sh)
- [install/herdr.sh](../../install/herdr.sh)
- [install/helix.sh](../../install/helix.sh)
- [install/php-dev.sh](../../install/php-dev.sh)
- [install/tailscale.sh](../../install/tailscale.sh)
- [install/atuin.sh](../../install/atuin.sh)
- [install/starship.sh](../../install/starship.sh)
- [install/go.sh](../../install/go.sh)
- [install/prebuilt-bins.sh](../../install/prebuilt-bins.sh)
- [bootstrap.sh](../../bootstrap.sh)
- [CLAUDE.md](../../CLAUDE.md)
- [AGENTS.md](../../AGENTS.md)
- [README.md](../../README.md)
