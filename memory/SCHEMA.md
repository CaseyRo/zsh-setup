# Total Recall Memory Schema

> Protocol documentation for the Total Recall memory system.
> Loaded every session. Teaches Claude how memory tiers work.

---

## Four-Tier Architecture

```
CLAUDE.local.md          ← Working memory (auto-loaded, ~1500 words)
memory/registers/        ← Domain registers (load on demand)
memory/daily/            ← Daily logs (append-only, chronological)
memory/archive/          ← Superseded / completed items (cold storage)
```

### Tier 1: Working Memory (`CLAUDE.local.md`)

- Auto-loaded every session
- Contains only behavior-changing facts
- ~1500 word soft limit — prune aggressively
- Updated inline during session when key facts change

### Tier 2: Registers (`memory/registers/`)

- Domain-specific files loaded when relevant
- Loaded on demand based on `_index.md` routing rules
- More detailed than working memory; less ephemeral than daily logs
- `open-loops.md` is treated as auto-load (checked every session)

### Tier 3: Daily Logs (`memory/daily/`)

- One file per day: `YYYY-MM-DD.md`
- Append-only during the day — never edit past entries
- First destination for new information before promotion
- Entries promoted to registers after they prove durable

### Tier 4: Archive (`memory/archive/`)

- Completed projects, superseded decisions, old daily logs
- Organized in `archive/projects/` and `archive/daily/`
- Cold storage — not loaded unless explicitly requested

---

## Write Gate Rules

Before writing anything to memory, ask: **"Does this change future behavior?"**

**Write if:**

- User corrects Claude's understanding of something
- A decision is made with rationale that will affect future work
- A preference is expressed that changes how Claude should respond
- A person's context, role, or relationship is established
- A project's state, goal, or blocker changes
- A commitment or deadline is made

**Skip if:**

- The fact is transient (one-session relevance)
- It's already captured accurately elsewhere
- It's general knowledge, not project-specific
- The user is just thinking out loud with no conclusion

---

## Read Rules

### Auto-loaded (every session)

- `CLAUDE.local.md` — working memory
- `memory/SCHEMA.md` — this file
- `memory/registers/open-loops.md` — active commitments

### Load on demand (see `_index.md`)

- `people.md` — when a person is mentioned by name
- `projects.md` — when a project is discussed
- `decisions.md` — when past choices are questioned
- `preferences.md` — when task involves user style/workflow
- `tech-stack.md` — when technical choices come up

### Never auto-load

- `memory/daily/` files — search only when explicitly needed
- `memory/archive/` — cold storage, explicit request only

---

## Routing Table

| Trigger | Destination |
|---------|------------|
| New preference expressed | `preferences.md` + working memory |
| Technical choice made | `tech-stack.md` |
| Decision with rationale | `decisions.md` |
| Person introduced | `people.md` |
| Project state changes | `projects.md` |
| Commitment / deadline | `open-loops.md` |
| Anything new (default) | Today's `daily/YYYY-MM-DD.md` |
| Completed project | `archive/projects/` |
| Old daily logs | `archive/daily/` |

---

## Contradiction Protocol

**Never silently overwrite.** When new information contradicts existing memory:

1. Note the contradiction explicitly
2. Mark old entry as superseded with date: `~~old entry~~ (superseded 2026-02-19)`
3. Write the new, correct entry
4. If significant, note the change in today's daily log

---

## Correction Handling

User corrections are **highest priority writes**:

1. Update working memory immediately
2. Find and correct all affected register entries
3. Add a note to today's daily log: `CORRECTION: [what changed]`
4. Never defend the old entry — accept and propagate

---

## Maintenance Cadences

### Immediate (during session)

- Log new facts to today's daily log
- Update working memory for behavior-changing facts
- Note contradictions and corrections

### End of session

- Review today's daily log for promotion candidates
- Promote durable facts to appropriate registers
- Update open-loops.md with new commitments

### Periodic (every few sessions)

- Prune working memory below 1500 words
- Archive completed items from registers
- Check open-loops.md for resolved items

### Quarterly

- Archive old daily logs (> 90 days) to `archive/daily/`
- Review decisions.md for outdated entries
- Clean up stale entries across all registers
