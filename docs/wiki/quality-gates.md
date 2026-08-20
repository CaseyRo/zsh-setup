# Quality gates

## Purpose [coverage: high, 5 sources]

Keep a repository of shell scripts honest without a test suite. There is no unit
test layer here; correctness is defended by static analysis at two strictness
levels, an end-to-end install that runs inside a container, and a version stamp
nobody has to remember to update.

## Architecture [coverage: high, 5 sources]

Four layers, each with a different job:

**Locally, pre-commit** runs shellcheck against both scopes, markdownlint with
`--fix`, and the version bump. Hooks are declared in `.pre-commit-config.yaml`.

**In the editor**, on dev machines, the same shellcheck binary runs live.
`bash-language-server` shells out to `shellcheck` whenever it is on `PATH`, so
the installer scope's rules surface as diagnostics while typing rather than at
commit or on push. Both binaries are installed by the dev arrays in
`install/packages.sh` for that reason. This is the earliest of the layers and
the only one that costs nothing to run.

**In continuous integration, two workflows** run on push and pull request
against `main`. `shellcheck.yml` first syntax-checks every `.sh` file with
`bash -n`, then runs shellcheck over the installer scope and the runtime scope
separately. It carries a second job, `version-stamp`, which compares `VERSION`
against `git rev-list --count HEAD`. That job is really a hook detector: the
stamp is the only locally generated artifact CI can see, so a mismatch is
evidence that the pre-commit hook did not run and therefore that the other
gates did not either. It needs `fetch-depth: 0`, since the default shallow
checkout reports a commit count of one, and on a pull request it reads the
branch head rather than the synthetic merge commit. `install-smoke.yml` builds a container image per distribution in a
matrix of ubuntu and debian, and runs the image.

**The smoke test is the only end-to-end check.** `test/Dockerfile.ubuntu`
creates an unprivileged user with passwordless sudo, copies the repository in,
and then runs the installer twice:

```dockerfile
RUN ./install.sh -y --light --skip-splash
RUN ./install.sh -y --light --skip-splash
```

The second invocation is the point. It is the idempotence contract expressed as
a build step, and it is what catches a module that errors instead of skipping
when its target already exists. The image's command then opens an interactive
zsh and checks that `cd` resolves, which exercises the whole loader including
the zoxide override that has to sort last.

## Key Decisions [coverage: high, 3 sources]

**Two shellcheck scopes, deliberately different strictness.** Installer scripts
(`install.sh`, `install/*.sh`, `bootstrap.sh`, `scripts/*.sh`) are real bash and
are held strictly: pre-commit runs them at `--severity=error`, continuous
integration at `--severity=warning`. Runtime shell code (`modules/**`,
`preload_configs/**`) is zsh being checked in bash mode, so it is run at
`--severity=warning` in both places and carries scoped inline disables for
known-good zsh idioms. Splitting the scopes is what allows the installer half to
stay strict instead of being dragged down to the tolerance the zsh half needs.

**`#`-prefixed files are excluded from the runtime scope.** The same prefix that
disables a file in the loader also removes it from linting, so retired code does
not have to keep passing checks.

**`.zshrc` is not shellchecked at all.** No shellcheck mode handles its mix of
`fpath+=`, the `include` helper, and operating system branches cleanly, so the
file is excluded rather than papered over with disables.

**Versioning is derived, never authored.** `scripts/bump-version.sh` writes
`2.0.<commit-count + 1>` into `VERSION` and stages it, as an always-run
pre-commit hook. Editing `VERSION` by hand only produces a conflict on the next
commit. The derivation holds only on machines where the hook is actually
installed, which is not all of them; see Gotchas.

**Deploy is commit and push.** There is no build artifact and no separate
deployment target. Pushing to `main` is the release.

## Gotchas [coverage: high, 6 sources]

markdownlint runs with `--fix`, so a commit touching markdown may quietly
rewrite formatting in your working tree. Rules that cannot be auto-fixed still
fail. `.markdownlint.yaml` disables the rules that fight this repository's
style (line length, first-line heading, emphasis as heading, bare code fences,
ordered list prefixes, table column style), and relaxes `MD024` to
`siblings_only` because OpenSpec specs repeat a scenario name under separate
requirements, which is meaningful rather than accidental.

Inline HTML and missing alt text stay enabled everywhere except the `README.md`
demo gallery, which is a two-column image grid that markdown tables cannot
express. That block carries a scoped `markdownlint-disable` comment naming only
`MD033` and `MD045`, with a reason, so the rest of the file stays checked.
Prefer that shape over widening the configuration: the narrow disable was worth
finding, because until it landed `pre-commit run --all-files`, the command this
repository documents as the way to run its own gates, could not pass on a clean
checkout.

The syntax check in continuous integration walks every `.sh` file in the
repository, including files the shellcheck steps skip. A file can pass
shellcheck's scope filters and still fail `bash -n`.

The smoke test only covers the `--light` path on Debian-family images. The macOS
path, the `--dev` profile, and Homebrew are not exercised anywhere automatically
and are verified by running the installer on a real machine. That gap matters
more since the Helix language servers landed, because everything they add sits
behind `--dev` and therefore behind the part no workflow runs.

Until recently `shellcheck` was in no package array at all, so the tool this
repository's primary gate depends on was never installed by its own installer.
Local pre-commit silently could not run, and the first real check was CI. When a
gate depends on a binary, the installer has to provide it.

`pre-commit` itself had the same shape until 2026-08-20, and it was the worse
case of the two, because the binary is not the gate. What gates a commit is
`.git/hooks/pre-commit`, which only exists once someone runs `pre-commit
install`. A machine with neither runs no hooks at all, and since the version
bump is one of them, `VERSION` quietly stops tracking the commit count. This
repository's own primary machine was found sixteen commits adrift, stamped
`2.0.190` against 206 commits, having committed without hooks for months.
That went uncaught for months because nothing looked: neither shellcheck scope
reads `VERSION`, so continuous integration stayed green throughout. The
`version-stamp` job now closes that, and it was checked against the drifted
commits themselves, which fail it, and against the repaired ones, which pass.
Merge commits are exempt, because hooks do not run on a merge and `VERSION`
conflicts on every one of them: both sides bumped it, so the stamp on a merge
reflects how somebody resolved a conflict rather than whether the gates ran.
The next ordinary commit is checked normally, which is where sustained drift
surfaces.

`install/pre-commit.sh` now provisions both halves on dev machines, with a
version floor described in [installer](installer.md). Two things it cannot do
for you. It is gated on the dev profile, so a machine set up without `--dev`
still commits ungated. And it runs at install time, so a repository cloned
afterwards needs `pre-commit install` of its own. Read a `VERSION` that
disagrees with `git rev-list --count HEAD` as evidence that the hooks are
missing rather than as a stale file to correct by hand.

A formatter is not automatically an improvement. Every formatter considered for
`configs/helix/languages.toml` was diffed against this repository first, and
three were rejected on the numbers: `shfmt` rewrites 1225 lines across the
installer scripts, `taplo` collapses the aligned palette columns in the herdr
and Helix configs, and `prettier` reindents the hand-maintained json. They are
recorded as documented absences in that file rather than quietly left out.

## Sources [coverage: high]

- [.pre-commit-config.yaml](../../.pre-commit-config.yaml)
- [.markdownlint.yaml](../../.markdownlint.yaml)
- [.github/workflows/shellcheck.yml](../../.github/workflows/shellcheck.yml)
- [.github/workflows/install-smoke.yml](../../.github/workflows/install-smoke.yml)
- [test/Dockerfile.ubuntu](../../test/Dockerfile.ubuntu)
- [scripts/bump-version.sh](../../scripts/bump-version.sh)
- [scripts/doctor.sh](../../scripts/doctor.sh)
- [install/packages.sh](../../install/packages.sh)
- [configs/helix/languages.toml](../../configs/helix/languages.toml)
- [CLAUDE.md](../../CLAUDE.md)
- [AGENTS.md](../../AGENTS.md)
