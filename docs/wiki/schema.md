# Wiki schema

Source of truth for this wiki's structure. Edit this file between compiles to
rename, merge, or split pages; the compiler respects those changes.

## Layout

This wiki follows the repository's `wiki-doctrine` skill, which overrides the
compiler's defaults where they conflict:

- Pages are flat markdown files in `docs/wiki/`, not `topics/` and
  `concepts/` subdirectories. Doctrine rule 2: a folder exists only when it
  holds several substantive pages.
- `quickstart.md` is the single entrypoint and carries the Map. There is no
  `INDEX.md` and no `CONTEXT.md`; agent navigation guidance lives inside
  `quickstart.md` instead of in a second front door. Doctrine rules 1 and 4.
- Sections per page: Purpose, Architecture, Key Decisions, Gotchas, Sources.
  The compiler's default `API Surface` and `Data` sections are dropped, because
  doctrine rule 0 deletes pages that paraphrase code and those two invite it.
  `Talks To` is dropped because nothing here talks to a service.

## Pages

| Page | Covers | Aliases |
|------|--------|---------|
| `quickstart` | Entry point, shortest path to running, Map | index, readme, getting started |
| `installer` | Provisioning: entry point and profiles, persisted state, platform detection, package lists, package-manager ladder, runtime versions, config seeding, failure isolation | install.sh, core.sh, packages, mise, profiles, light, dev, idempotence, seeding, symlink, helix, composer, tailscale, brew prefix, set -e |
| `shell-runtime` | Loader order, per-operating-system scoping, `zz_` tail-init contract, `#` opt-out convention, startup cost, guarded environment defaults | .zshrc, modules, preload_configs, load order, zz_, compinit, completions, zoxide, EDITOR, env.sh |
| `quality-gates` | Two shellcheck scopes, pre-commit, versioning, continuous integration smoke test | shellcheck, pre-commit, markdownlint, VERSION, bump-version, docker, smoke test |

## Concepts

None. One pattern does connect all three pages, that ordering and idempotence
constraints in this repository fail silently rather than loudly, but a single
cross-cutting page would be a stub. Doctrine rule 3 sends it upward instead: it
is stated in `quickstart.md` under "Where the knowledge lives" and demonstrated
in each page's Gotchas.

Re-evaluated on 2026-08-06 and deliberately kept empty. The 2026-08-06 compile
added four fresh instances of the pattern (a skip guard satisfied by a broken
binary, a renamed package defeating both install and guard, a module return
value ending the whole run, a pipeline exit status swallowing a failed lookup),
which strengthens the pattern but does not change where it belongs. A concept
page would mostly link back to three Gotchas sections, which is the duplication
doctrine rule 4 forbids and the stub rule 3 forbids. The canonical home stays
`quickstart.md`, now stated more concretely there.

Revisit if a fourth page lands and the pattern earns a home of its own.

## Evolution log

- 2026-07-30: Initial schema generated from 3 pages plus quickstart, 0 concepts.
  Structure adjusted from compiler defaults to satisfy the `wiki-doctrine`
  skill; deviations recorded under Layout above and in `.wiki-compiler.json`.
- 2026-08-06: No pages added or removed. Aliases extended on `installer` and
  `shell-runtime` to cover the Helix, failure-isolation, and guarded-default
  material added this compile. Concepts re-evaluated and still none; reasoning
  recorded under Concepts above.
