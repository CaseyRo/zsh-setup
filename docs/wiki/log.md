# Compile log

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
