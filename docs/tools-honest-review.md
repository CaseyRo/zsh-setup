# Toolkit: what we actually use

Evidence, 2026-11-02: atuin history on both Macs (about 6,900 commands) plus every Bash
command Claude ran in `~/.claude/projects` transcripts. Shell integrations (zoxide, fzf,
atuin, starship, carapace) never show up as typed commands, so they are judged separately.

## Used for real

### herdr — 164 uses (140 are `herdr --remote cc1`)

![herdr](gifs/herdr.gif)

1. **Drive cc1 from the Air.** `herdr --remote cc1` is the daily entry point to the
   Claude sessions. Keep it; it is the single most-used command here.
2. **Park and resume agent sessions.** `herdr --session <name>` plus `session attach`
   survives a closed laptop, which is how Things-started jobs like this one run.
3. **Wire agents in.** `herdr integration install claude` makes the Claude hook show
   session state in the workspace list. Done once per machine.

### topgrade — 32 uses

![topgrade](gifs/topgrade.gif)

1. **Weekly "update everything".** Plain `topgrade` is 27 of 32 runs. It replaces
   `brew upgrade`, `cargo install-update` and `mise upgrade` as three separate habits.
2. **Preview first.** `topgrade --dry-run --only brew_formula --only cargo` lists what
   would run. Use it before a travel day.
3. **Skip what breaks.** `--disable system` is already in your history; make it a config
   entry in `topgrade.toml` instead of a flag you retype.

### helix (`hx`) — 18 uses, mostly one file

1. **Quick markdown edits.** `hx feedback.md` is 12 of 18 runs. That is the real job:
   a fast editor for prose and notes, not an IDE.
2. **Config and shell files over SSH.** Single static binary with LSP built in, so no
   plugin setup on a fresh server.
3. **Learn the keys once.** `hx --tutor` (2 runs) is there; finish it or stop installing it.

### eza — 17 uses

1. **`eza --icons` as the default `ls`.** 13 of 17 uses. It is a habit, not a workflow.
2. **`eza -l --git`** shows git status per file, useful inside repos.
3. **`eza --tree -L 2`** replaces `tree` for a quick layout. Not in your history yet.

### jq — 5 typed, 561 by Claude

1. **Shape `op` output.** All typed uses are `op ... --format=json | jq '{id, title, ...}'`.
2. **Claude's glue.** 561 calls across transcripts: MCP and API responses, package files.
   This is the one tool Claude depends on every day.
3. **`jq -r` to feed shell loops**, for example listing Komodo stacks into a `for` loop.

### btop — 6 uses, all on servers

1. **Look at a server over mosh.** `mosh host -- byobu new-session -A -s mon-<host> btop`
   is the pattern in your history for smurf, werkstatt and werkzettel.
2. **Fleet spot-check** before a deploy. One session per host, re-attach any time.
3. **Skip it on the Macs.** Zero local uses.

## Occasional, keep but do not document further

`zellij` (5, only to try it), `yt-dlp` (3 real downloads), `llmfit` (2, install plus one
run), `glow` (1), `rg` (53 by Claude, 0 typed).

## Zero use in either history: verdict

| Tool | Verdict | Reason |
|------|---------|--------|
| fd | keep, quietly | fzf and zoxide-style pickers shell out to it; never typed |
| bat, delta | keep | pager and git-diff plumbing, works invisibly |
| fzf, zoxide, atuin, starship, carapace | keep | shell integrations, in use (1,584 `cd`) |
| lazygit, jj, yazi | drop candidate | no runs on either Mac; Claude drives git |
| xh, ouch, jnv, yq, sd | drop candidate | nothing typed, Claude uses its own tools |
| dust, duf, dysk, procs, bandwhich | drop candidate | btop covers it; never run |
| hyperfine, tokei, fastfetch, tldr | drop candidate | never run |
| parsync | drop candidate | never run |

## Open questions for Casey

Interactive Q&A, because the history cannot answer these:

1. **lazygit / jj / yazi:** is there a workflow you want that you have not started, or
   do we drop all three?
2. **fastfetch:** wanted for the login splash, or just a default?
3. **parsync:** was there a specific big-transfer job in mind?
4. **yq, xh, ouch:** do any of these replace something you still do by hand?

Nothing was removed from `install/packages.sh`. Answer the questions and the drop
candidates become one small PR.
