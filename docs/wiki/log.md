# Compile log

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
