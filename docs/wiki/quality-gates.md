# Quality gates

## Purpose [coverage: high, 5 sources]

Keep a repository of shell scripts honest without a test suite. There is no unit
test layer here; correctness is defended by static analysis at two strictness
levels, an end-to-end install that runs inside a container, and a version stamp
nobody has to remember to update.

## Architecture [coverage: high, 4 sources]

Three layers, each with a different job:

**Locally, pre-commit** runs shellcheck against both scopes, markdownlint with
`--fix`, and the version bump. Hooks are declared in `.pre-commit-config.yaml`.

**In continuous integration, two workflows** run on push and pull request
against `main`. `shellcheck.yml` first syntax-checks every `.sh` file with
`bash -n`, then runs shellcheck over the installer scope and the runtime scope
separately. `install-smoke.yml` builds a container image per distribution in a
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
pre-commit hook. The version therefore tracks history exactly and cannot drift.
Editing `VERSION` by hand only produces a conflict on the next commit.

**Deploy is commit and push.** There is no build artifact and no separate
deployment target. Pushing to `main` is the release.

## Gotchas [coverage: medium, 3 sources]

markdownlint runs with `--fix`, so a commit touching markdown may quietly
rewrite formatting in your working tree. Rules that cannot be auto-fixed still
fail. `.markdownlint.yaml` disables the rules that fight this repository's
style (line length, first-line heading, emphasis as heading, bare code fences,
ordered list prefixes, table column style) but leaves inline HTML enabled, and
`README.md` contains a deliberate HTML table of demo images. Expect that file to
report violations when linted directly.

The syntax check in continuous integration walks every `.sh` file in the
repository, including files the shellcheck steps skip. A file can pass
shellcheck's scope filters and still fail `bash -n`.

The smoke test only covers the `--light` path on Debian-family images. The macOS
path, the `--dev` profile, and Homebrew are not exercised anywhere automatically
and are verified by running the installer on a real machine.

## Sources [coverage: high]

- [.pre-commit-config.yaml](../../.pre-commit-config.yaml)
- [.markdownlint.yaml](../../.markdownlint.yaml)
- [.github/workflows/shellcheck.yml](../../.github/workflows/shellcheck.yml)
- [.github/workflows/install-smoke.yml](../../.github/workflows/install-smoke.yml)
- [test/Dockerfile.ubuntu](../../test/Dockerfile.ubuntu)
- [scripts/bump-version.sh](../../scripts/bump-version.sh)
- [scripts/doctor.sh](../../scripts/doctor.sh)
- [CLAUDE.md](../../CLAUDE.md)
- [AGENTS.md](../../AGENTS.md)
