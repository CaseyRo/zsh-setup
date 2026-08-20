# Compile log

## 2026-08-20

**Pages updated:** shell-runtime, installer, quality-gates, quickstart
**New pages:** none
**Concepts:** none (re-evaluated; see schema.md)
**Sources scanned:** 105
**Sources changed:** 4

Notes:

- Two mechanisms turned out to be entirely undocumented rather than merely
  stale: the daily self-update in `modules/common/auto-update.sh`, and the
  `install/upgrade.sh` re-provisioning path it drives. Split by canonical home,
  the trigger to `shell-runtime` and the payload to `installer`, cross-linked
  rather than restated.
- `quality-gates` carried a claim that is now known to be false: that `VERSION`
  tracks history exactly and cannot drift. It can, and on this machine it had,
  by sixteen commits. Corrected in Key Decisions and explained in Gotchas, folded
  into the existing gate-depends-on-an-uninstalled-binary paragraph rather than
  added as a separate one.
- `quickstart` went from three recurring constraints to four. The self-update
  failure introduced a shape the other three do not cover: work detached to keep
  the prompt fast is still attached to the terminal, and a stopped job holds its
  lock with no error anywhere.
- The `installer` gotcha about `VERSION` was re-pointed at `quality-gates`
  instead of re-explaining the rule, per doctrine rule 4.
- Source count fell from 136 to 105. The `.claude/` OpenSpec boilerplate was
  deleted from the repository in 4918b3b; the remainder is a difference in how
  the patterns were counted, not content that went missing.
- Compiled inline rather than through parallel subagents; four affected pages
  did not justify the fan-out.

Amended later the same day, after `pre-commit` was installed on this machine:

- With the hook actually running, `pre-commit run --all-files` turned out not to
  pass on a clean checkout, so the command CLAUDE.md documents as the way to run
  the gates was broken. Two causes, both pre-existing. `README.md`'s demo gallery
  tripped `MD033` and `MD045`, and `openspec/specs/setup-installer/spec.md`
  tripped `MD024` on a scenario name repeated under a different requirement.
- Fixed narrowly rather than by widening the configuration: a scoped
  `markdownlint-disable` around the gallery naming just the two rules, and
  `MD024: siblings_only` so duplicates are still caught between actual siblings.
  Both were verified by probe, confirming the rules still fire outside the
  narrowed scope.
- `quality-gates` Gotchas rewritten accordingly; it had described the README
  breakage as permanent.

Third pass the same day, closing the installer gap:

- `install/pre-commit.sh` added, plus the two other edits a new installer module
  needs (a `source` line and a `main` call). It installs the binary and then the
  hook, treating the hook as the deliverable.
- Deliberately not routed through apt. The package exists on both Linux targets
  and is too old to parse this repo's config: Ubuntu 22.04 ships 2.17.0 and
  Raspberry Pi OS bookworm ships 3.0.4, against a floor of 3.2.0. Verified by
  running 3.0.4, 3.1.1 and 3.2.0 against the config; 3.2.0 is the exact
  boundary. Recorded as a Key Decision on `installer`.
- `quality-gates` corrected again: it had said pre-commit still had the
  uninstalled-gate shape, which stopped being true with this change.

Fourth pass, closing the detection gap:

- `shellcheck.yml` gained a `version-stamp` job comparing `VERSION` to the
  commit count. It is a hook detector rather than a versioning check: the stamp
  is the only locally generated artifact continuous integration can see, so a
  mismatch is evidence the pre-commit hook did not run and the other gates did
  not either.
- Merge commits are exempt. Establishing that took a simulation rather than
  reading history, because this repository's own history is polluted by the
  drift being fixed. The finding was that `VERSION` conflicts on every merge,
  since both sides bump it, so the stamp on a merge records a human's conflict
  resolution rather than whether gates ran.
- Verified against real commits: the drifted ones fail the job, the repaired
  ones pass, the two merge commits skip.
- `quality-gates` Architecture and Gotchas both updated; the page had said
  nothing catches this, which was true when written that morning.

## 2026-08-06 (second pass)

**Pages updated:** installer, quality-gates
**New pages:** none
**Concepts:** none
**Sources scanned:** 136
**Sources changed:** 6

Notes:

- Covers the Helix language server work: new `_DEV` package arrays,
  `configs/helix/languages.toml`, and the npm skip-guard fix found while
  landing it.
- The npm `--depth=0` bug is the fourth instance of the presence-is-not-health
  pattern, so it was merged into that paragraph in `installer.md` rather than
  given its own gotcha. Concepts still stay empty for the reason recorded in
  `schema.md`.
- `quality-gates.md` gained a fourth layer: shellcheck now runs live in the
  editor through bash-language-server. The same page records that shellcheck was
  previously in no package array at all, so local pre-commit could not run.

## 2026-08-06

**Pages updated:** installer, shell-runtime, quickstart
**New pages:** none
**Concepts:** none (re-evaluated this run, see schema.md)
**Sources scanned:** 135
**Sources changed:** 9

Notes:

- Incremental compile covering commits `e3c0ff7..61bbef5`: the Helix addition
  plus three installer fixes found while running it (composer, Tailscale, the
  macOS default-shell check).
- `installer.md` gained a Key Decision on failure isolation and a rewritten
  Gotchas section. The presence-is-not-health rule was already stated for mise,
  so the composer case was merged into that paragraph rather than given its own,
  per doctrine rule 4.
- `shell-runtime.md` gained a Key Decision on guarded environment defaults,
  covering `EDITOR` and `VISUAL` in `preload_configs/common/env.sh`.
- Two em-dashes introduced by a hand edit to `installer.md` between compiles were
  removed. The wiki is now at zero, matching the doctrine's style rule.
- Compiled inline rather than through parallel subagents; two affected pages did
  not justify the fan-out.

## 2026-07-30

**Pages created:** quickstart, installer, shell-runtime, quality-gates
**New pages:** all (first compile)
**Concepts:** none (see schema.md for why)
**Sources scanned:** 113
**Sources changed:** 113 (first run treats everything as new)

Notes:

- Structure follows the `wiki-doctrine` skill rather than the compiler defaults.
  Flat pages in `docs/wiki/`, `quickstart.md` as the only entrypoint, no
  `INDEX.md`, no `CONTEXT.md`, no `concepts/`. Recorded in `schema.md`.
- `.claude/` is excluded from sources. Its 10 markdown files under
  `commands/opsx` are OpenSpec plugin boilerplate, identical across repositories
  and carrying no project knowledge.
- Compiled inline rather than through parallel subagents.
- Uncommitted at compile time and therefore included: `configs/herdr/config.toml`
  and `install/herdr.sh`, both referenced from `installer.md`.
