// Workspace spaces: stable colored avatars, worktrees under their checkout,
// grouped by machine when more than one is known. After a space's name, the repo
// its first terminal is in now, only where unusual: branch, ahead/behind. Click to
// switch, right-click for its menu, drag to reorder.
// Cockpit: each space's agents nest under it, saying their state in words.
// Ochre (theme `blocked`) means "needs you" and nothing else; done stays stamped
// with its finish time until someone looks (Herdr turns it idle then).

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, machines, panes, agents, setAgentOrder, home, run, openOverlay, exec, hc, theme, shared, setShared, watchFolder, window, layout } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// Where a space is now: its first terminal's live folder, else where it was made.
// `ps`: panes(), read once by the caller (each read copies every pane).
function place(s, ps) {
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return ps.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
}
// The list is three fixed columns, so every line starts on the same x and the
// eye runs straight down: the key that jumps here, a 12px mark, then the words.
const PAD = 14;   // a band's left inset; bands run edge to edge, so rows pad themselves
const KEY = 22;   // the M-key column
const NEST = 10;  // how far an agent sits inside its space
const ROW = 26;
const where = (s, ps) => JSON.stringify([s.machine ?? null, place(s, ps)]);
const base = (path) => path.replace(/\/+$/, "").split("/").pop();
// Changes made outside Herdr (an editor's save, a commit in another app): looked
// for this often, in repos the list shows, while the window is in front.
const FALLBACK = 60000;

// What a stored color name looks like on an avatar (the same in every mod
// that draws space avatars): one strong color per hue, light and dark alike.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// Which key jumps here. The Q11's M1-M5 send `space.select --index 1-5`
// (~/dev/keychron-q11), and `i` is that index, so only the first five spaces
// have a key to name — the sixth gets no label rather than a wrong one.
const mKey = (i) => (i < 5 ? `M${i + 1}` : null);

const slot = (child) => h_flex().w(12).flex_none().items_center().justify_center().child(child);

// One status mark, drawn rather than typed, in that fixed column. Colour lives
// here and nowhere else in a row, so the words stay in the readable tones on
// every background: a spinner while it works, a check when it finished, a
// quiet dot when it has nothing to say. Blocked rows are ochre all over.
function marker(status, t, ink) {
  if (status === "blocked") return slot(div().size(7).rounded(4).bg(ink));
  if (status === "working") return slot(svg("mods/workspace-chrome/spinner.svg").size(11).text_color(t.working).spin(900));
  if (status === "done") return slot(svg("mods/workspace-chrome/check.svg").size(11).text_color(t.done));
  return slot(div().size(4).rounded(2).bg(t.idle));
}

const PINE = "#283128"; // brand ink: text and marks on the ochre fill
const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();
const WORD = { blocked: "needs you", working: "working", done: "done", idle: "idle" };

function since(ms) {
  const m = Math.floor((Date.now() - ms) / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}
const clock = (ms) => new Date(ms).toTimeString().slice(0, 5);

// Claude Code's status-line input, saved per Herdr terminal by the fleet
// statusline-command.sh: one line per file, "<terminal>\t<json>".
const CLAUDE_STATUS = `d="\${XDG_STATE_HOME:-$HOME/.local/state}/claude-status"
for f in "$d"/*.json; do [ -f "$f" ] || continue; printf '%s\t' "$(basename "$f" .json)"; tr -d '\n' < "$f"; echo; done`;

// What an agent is called: its tab's name when someone named it, else the
// folder it works in, else its program.
function agentName(a, tab, ps) {
  if (tab?.named) return tab.name;
  const cwd = ps.find((p) => p.pane === a.pane)?.cwd;
  if (!cwd) return a.program?.name ?? "agent";
  return cwd.replace(/\/+$/, "") === home().replace(/\/+$/, "") ? "~" : base(cwd);
}

// The session's own name. `claude -n <name>` reaches Herdr as the terminal
// title, so this is the name Casey gave the work. Only a title that cannot be
// a name is dropped - a path, an address, or the program announcing itself -
// because the row's job is to say which session this is; the mark beside it
// already says how it is doing. A title that repeats its folder is kept: that
// is a session named after where it works, not a title saying nothing.
function sessionName(a) {
  const live = clean(a.title);
  const useless = !live || live === a.program?.name || /^[~/]/.test(live) || live.includes("@");
  return useless ? null : live;
}

export default class Spaces extends View {
  init(_props, cx) {
    this.git = {}; // where() -> { name, branch, ahead, behind, repo, linked }, null: not a repo
    this.checked = {}; // where() -> when it was last looked at
    this.unsure = new Set(); // where()s git couldn't answer for (a machine away)
    this.pending = new Set(); // where()s to look at next
    this.busy = {}; // pane -> an agent working or a program in front of its shell
    this.ready = {}; // machine -> its layout was readable at the last look
    this.at = {}; // space -> its where() at the last look
    this.watching = new Set(); // local repos' git folders
    // Spaces made while this runs wait (at most a moment) for their git, so a
    // worktree appears under its repo instead of jumping there.
    this.shown = new Set(spaces().map((s) => s.id));
    this.born = {};
    this.pressed = null;
    this.over = null;
    this.hovered = null; // the machine header under the pointer, for its New space
    this.machines = [];
    this.reconnecting = JSON.parse(localStorage.getItem("machines.reconnecting") ?? "{}");
    for (const state of Object.values(this.reconnecting)) state.busy = false;
    this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]"));
    this.refreshMachines(cx);
    cx.timer.every(15000, cx => this.refreshMachines(cx));
    // `git status` walks the whole tree, on another machine a process there:
    // only when its answer could have changed (see `due`).
    cx.timer.every(250, (cx) => this.checkNew(cx));
    // Context and usage change once per Claude turn; ten seconds is plenty.
    this.refreshClaude(cx);
    cx.timer.every(10000, (cx) => this.refreshClaude(cx));
  }

  // Each machine's saved status lines, shared as { agents: {address: {ctx}}, week }
  // so the horizon strip can show the account-wide 7-day usage.
  refreshClaude(cx) {
    cx.spawn(async () => {
      const on = [...new Set(spaces().map((s) => s.machine ?? null))];
      const agents = {};
      let week = null;
      for (const m of on) {
        let r;
        try { r = await exec("sh", ["-c", CLAUDE_STATUS], m ? { on: m } : {}); } catch { continue; }
        for (const line of (r.stdout ?? "").split("\n")) {
          const tab = line.indexOf("\t");
          if (tab < 1) continue;
          let j;
          try { j = JSON.parse(line.slice(tab + 1)); } catch { continue; }
          const ctx = j?.context_window?.remaining_percentage;
          agents[m ? `${m}/${line.slice(0, tab)}` : line.slice(0, tab)] = { ctx: typeof ctx === "number" ? ctx : null };
          const w = j?.rate_limits?.seven_day;
          // The freshest window: latest reset, then the most used (use only grows within a window).
          if (typeof w?.used_percentage === "number" && typeof w?.resets_at === "number"
            && (!week || w.resets_at > week.resets_at || (w.resets_at === week.resets_at && w.used_percentage > week.used_percentage))) week = w;
        }
      }
      const next = { agents, week };
      if (JSON.stringify(next) !== JSON.stringify(shared("claude.status") ?? null)) setShared("claude.status", next);
    });
  }

  checkNew(cx) {
    const now = Date.now();
    const sp = spaces();
    for (const s of sp) if (!this.shown.has(s.id)) this.born[s.id] ??= now;
    const due = this.due(now, sp, panes());
    if (due.size) this.refreshGit(due, cx);
    if (sp.some((s) => !this.shown.has(s.id))) cx.notify();
  }

  // Places whose git could have changed: new ones (a new space, a cd), where a
  // command or an agent's turn just ended (a checkout, a commit, edits), those on
  // a machine that is back, and repos in view whose fallback is due.
  due(now, sp, ps) {
    // Moved there: what it knew of that place may be old.
    const at = {};
    for (const s of sp) at[s.id] = where(s, ps);
    const keys = new Set(Object.values(at).filter((k) => JSON.parse(k)[1]));
    const due = new Set([...keys].filter((k) => !(k in this.git)));
    for (const [id, k] of Object.entries(at)) if (this.at[id] && this.at[id] !== k && keys.has(k)) due.add(k);
    this.at = at;
    const spaceOf = {};
    for (const s of sp) for (const t of s.tabs ?? []) spaceOf[t.id] = s;
    const busy = {};
    for (const p of ps) {
      if (!p.terminal || !spaceOf[p.tab]) continue;
      busy[p.pane] = p.status === "working" || !(p.program?.shell || p.program?.agent);
      if (this.busy[p.pane] && !busy[p.pane]) this.sameRepo(at[spaceOf[p.tab].id], keys).forEach((k) => due.add(k));
    }
    this.busy = busy;
    for (const m of machines()) {
      const ready = m.layout === "ready";
      if (ready && this.ready[m.name] === false) for (const k of keys) if (JSON.parse(k)[0] === m.name) due.add(k);
      this.ready[m.name] = ready;
    }
    if (window().active) {
      for (const k of keys) {
        const asks = this.git[k] || this.unsure.has(k);
        if (asks && !this.folded.has(JSON.parse(k)[0]) && now - (this.checked[k] ?? 0) > FALLBACK) due.add(k);
      }
    }
    return due;
  }

  // `key` and the other places in its repo (a commit there moves their ahead/behind).
  sameRepo(key, keys) {
    const repo = this.git[key]?.repo;
    return [key, ...(repo ? [...keys].filter((k) => this.git[k]?.repo === repo) : [])];
  }

  refreshMachines(cx) {
    cx.spawn(async cx => {
      try { const r = await hc(["machine", "ls", "--json"]); if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => !m.temporary); } catch {}
      cx.notify();
    });
  }

  rebuilt(machine) {
    return machine?.state === "unreachable" && /^a different core answers there \("[^"]+"\)$/.test(machine.why ?? "");
  }

  reconnect(machine, cx) {
    const name = machine.name;
    if (this.reconnecting[name]?.busy) return;
    const state = this.reconnecting[name] ??= { machine, removed: false };
    state.busy = true;
    state.error = null;
    localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
    cx.notify();
    cx.spawn(async cx => {
      try {
        const ask = async args => {
          const r = await hc([...args, "--json"]);
          if (r.code !== 0) {
            let error;
            try { error = JSON.parse(r.stdout || r.stderr).error?.message; } catch {}
            throw new Error(error || r.stderr || r.stdout || "Couldn't connect.");
          }
        };
        if (!state.removed) {
          await ask(["machine", "rm", name]);
          state.removed = true;
          localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
        }
        const args = ["machine", "add"];
        if (machine.via) args.push("--via", machine.target);
        else args.push(machine.target);
        args.push("--name", name);
        if (machine.session) args.push("--session", machine.session);
        if (machine.temporary) args.push("--temp");
        await ask(args);
        this.folded.delete(name);
        localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
        delete this.reconnecting[name];
      } catch (e) {
        state.error = String(e.message ?? e);
        state.busy = false;
      }
      localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
      this.refreshMachines(cx);
      cx.notify();
    });
  }

  // One look at a time, each place once however often it was asked for meanwhile.
  refreshGit(keys, cx) {
    for (const k of keys) this.pending.add(k);
    if (this.refreshing) return;
    this.refreshing = true;
    cx.spawn(async (cx) => {
      while (this.pending.size) {
        const keys = [...this.pending];
        this.pending.clear();
        for (const key of keys) await this.check(key, cx);
      }
      const used = new Set(Object.values(this.git).filter(Boolean).map((g) => JSON.parse(g.repo)).filter(([on]) => !on).map(([, repo]) => repo));
      for (const repo of this.watching) if (!used.has(repo)) this.watching.delete(repo);
      this.refreshing = false;
      cx.notify();
    });
  }

  // One place's git: branch, ahead/behind, its repo.
  async check(key, cx) {
    const [on, cwd] = JSON.parse(key);
    this.checked[key] = Date.now();
    this.unsure.delete(key);
    try {
      // No optional locks: a status that touched the index would wake the watch again.
      // Writes nothing under .git (index lock, fsmonitor cookie): watch() would wake on it.
      const r = await exec("git", ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain=v2", "--branch"], { cwd, on });
      if (r.code !== 0) {
        // Only git's own "no" is remembered as no repo; anything else is asked again.
        if (!/not a git repository/i.test(r.stderr)) this.unsure.add(key);
        this.git[key] = null;
        return;
      }
      // The repo's own .git folder names it; a worktree's top differs from it.
      const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
      const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd, on });
      const repo = common.stdout.trim();
      const name = repo.endsWith("/.git") ? base(repo.slice(0, -5)) : base(repo).replace(/\.git$/, "");
      const info = { name, branch: null, ahead: 0, behind: 0, repo: JSON.stringify([on, repo]), linked: repo !== `${top.stdout.trim()}/.git` };
      for (const line of r.stdout.split("\n")) {
        if (line.startsWith("# branch.head ")) info.branch = line.slice(14);
        else if (line.startsWith("# branch.ab ")) {
          const [a, b] = line.slice(12).split(" ");
          info.ahead = Math.abs(parseInt(a, 10)) || 0;
          info.behind = Math.abs(parseInt(b, 10)) || 0;
        }
      }
      this.git[key] = info;
      if (!on) this.watch(repo, cx);
    } catch {
      // Couldn't ask (the machine is away): keep what it showed, look again later.
      this.git[key] ??= null;
      this.unsure.add(key);
    }
  }

  watch(repo, cx) {
    if (this.watching.has(repo)) return;
    this.watching.add(repo);
    cx.spawn(async (cx) => {
      try {
        while (this.watching.has(repo)) {
          await watchFolder(repo);
          const mine = JSON.stringify([null, repo]);
          if (this.watching.has(repo)) this.refreshGit(Object.keys(this.git).filter((k) => this.git[k]?.repo === mine), cx);
        }
      } catch { this.watching.delete(repo); }
    });
  }

  menu(w) {
    // A popup is as tall as its items; height is only the most.
    openOverlay({ mod: "menu", kind: "popup", width: 200, height: 260, props: { tab: "space", target: { id: w.id } } });
  }

  // Spaces in order, each worktree space moved under its main checkout's.
  ordered() {
    const sp = spaces(), ps = panes();
    const ready = (w) => this.shown.has(w.id) || where(w, ps) in this.git || Date.now() - (this.born[w.id] ??= Date.now()) > 1500;
    for (const w of sp) if (!this.shown.has(w.id) && ready(w)) this.shown.add(w.id);
    const list = sp.map((w, i) => ({ w, i, g: this.git[where(w, ps)] ?? null })).filter((r) => this.shown.has(r.w.id));
    const mains = new Set(list.filter((r) => r.g && !r.g.linked).map((r) => r.g.repo));
    const nested = (r) => r.g?.linked && mains.has(r.g.repo);
    const out = [];
    const placed = new Set(); // repos whose worktrees are listed (under the first of its spaces)
    for (const r of list) {
      if (nested(r)) continue;
      out.push({ ...r, tree: null });
      if (!r.g || r.g.linked || placed.has(r.g.repo)) continue;
      placed.add(r.g.repo);
      const kids = list.filter((k) => nested(k) && k.g.repo === r.g.repo);
      kids.forEach((k, n) => out.push({ ...k, tree: n === kids.length - 1 ? "└─" : "├─" }));
    }
    return out;
  }

  // The rows, under a header per machine once one isn't this computer.
  grouped(t, collapsed) {
    const rows = this.ordered();
    const all = agents(), ps = panes();
    const order = [];
    const draw = (r, n) => {
      if (collapsed) return this.compact(r, t);
      const mine = all.filter((a) => a.space === r.w.id);
      order.push(...mine.map((a) => a.address));
      return [this.row(r, t, n === 0), ...mine.map((a) => this.agentRow(a, r.w, t, ps))];
    };
    // agent.next / agent.prev walk the agents in sidebar order.
    this.order = order;
    const remote = [...new Set([...rows.map(r => r.w.machine).filter(Boolean), ...this.machines.map(m => m.name), ...Object.keys(this.reconnecting)])].sort();
    const loading = m => {
      const layout = machines().find(k => k.name === m)?.layout;
      return layout === "loading" || (!layout && this.machines.some(k => k.name === m && k.state === "connected"))
        || spaces().some(s => (s.machine ?? null) === m && !this.shown.has(s.id));
    };
    const loadingRow = m => div().id(`machine-loading-${m ?? "local"}`).h(26).flex_none().px(PAD).text_size(12).text_color(t.dim).child(collapsed ? "…" : "Loading…");
    if (!remote.length) return loading(null) && !rows.length ? [loadingRow(null)] : rows.flatMap(draw);
    const machineNames = [null, ...remote];
    return machineNames.flatMap((m) => {
      const mine = rows.filter((r) => (r.w.machine ?? null) === m);
      const repair = this.reconnecting[m];
      const machine = this.machines.find(k => k.name === m) ?? repair?.machine;
      const connected = !m || machine?.state === "connected";
      const rebuilt = this.rebuilt(machine) || !!repair;
      const folded = this.folded.has(m);
      // A machine is a label, not a control panel: at rest it says its name and
      // only what isn't normal. A connected machine needs no green dot to say
      // so, the chevron is worth drawing only where something is folded away,
      // and New space comes out when the pointer is on the row.
      const over = this.hovered === (m ?? "local");
      const waiting = agents().filter(a => a.status === "blocked" && (spaces().find(s => s.id === a.space)?.machine ?? null) === m).length;
      const head = h_flex().id(`machine-${m ?? "local"}`).h(24).flex_none().mt(12).px(collapsed ? 2 : PAD).gap(7).items_center().text_size(10.5).text_color(t.dim)
        .cursor_pointer().hover(s => s.bg(t.hover))
        .on_hover((on, cx) => {
          const now = on ? (m ?? "local") : this.hovered === (m ?? "local") ? null : this.hovered;
          if (this.hovered !== now) { this.hovered = now; cx.notify(); }
        })
        .on_click((_e, cx) => {
          folded ? this.folded.delete(m) : this.folded.add(m);
          localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/${m ? "server" : "monitor"}.svg`).size(collapsed ? 13 : 11).flex_none())
        .when(!collapsed, el => el.child(div().flex_1().truncate().child(m ?? "This computer"))
          .when(!connected && !rebuilt, el => el.child(div().flex_none().child((machine?.state ?? "asleep").replace(/_/g, " "))))
          .when(rebuilt, el => el.child(h_flex().flex_none().gap(3).items_center()
            .child(div().max_w(140).truncate().child(repair?.error || "rebuilt ·"))
            .child(div().id(`machine-connect-${m}`).text_color(repair?.error ? t.blocked : t.muted)
              .hover(s => s.text_color(t.foreground))
              .tooltip(repair?.error || "This machine was rebuilt or replaced. Click to connect to the new one.")
              .on_click((_e, cx) => { cx.stop_propagation(); this.reconnect(machine, cx); })
              .child(repair?.busy ? "Connecting…" : "Connect"))))
          // Folded away is the one state that can hide an agent needing Casey.
          .when(folded && waiting > 0, el => el.child(div().flex_none().px(5).rounded(4).bg(t.blocked).text_color(PINE).font_semibold().child(`${waiting} waiting`)))
          .when(folded, el => el.child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none()))
          // On hover the row says what it can do; at rest it says nothing.
          .when(over && !folded, el => el.child(svg("mods/workspace-chrome/chevron-down.svg").size(11).flex_none()))
          .when(connected && over, el => el.child(div().id(`machine-add-${m ?? "local"}`).flex_none().flex().items_center()
            .hover(s => s.text_color(t.foreground))
            .tooltip(`New space on ${m ?? "this computer"}`)
            .on_click((_e, cx) => { cx.stop_propagation(); run("space.new", { machine: m ?? "" }); })
            .child(svg("mods/workspace-chrome/plus.svg").size(11)))));
      const empty = h_flex().id(`machine-new-${m ?? "local"}`).h(26).flex_none().px(PAD).gap(7).items_center()
        .text_size(12).text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
        .on_click(() => run("space.new", { machine: m ?? "" }))
        .child(svg("mods/workspace-chrome/plus.svg").size(12)).when(!collapsed, el => el.child("New space there"));
      if (!collapsed && rebuilt) return [head];
      return [head, ...(folded ? [] : mine.length ? mine.flatMap(draw) : [loading(m) ? loadingRow(m) : empty])];
    });
  }

  // Only what's unusual, after the name: "herdr \u00b7 spike \u21912 \u21931". The repo or
  // branch goes when the name already says it (a worktree is named after its branch),
  // and master/main go: nearly every space is on one.
  gitTail(g, tree, name, t) {
    const raw = g.branch ?? "detached";
    const same = (a) => a.toLowerCase() === name.toLowerCase();
    const branch = same(raw) || raw === "master" || raw === "main" ? "" : raw;
    const repo = tree || same(g.name) ? "" : g.name;
    const where = [repo, branch].filter(Boolean).join(" \u00b7 ");
    return h_flex()
      .flex_1()
      .min_w(0)
      .gap(5)
      .justify_end()
      .items_center()
      .text_size(11.5)
      .text_color(t.dim)
      .when(Boolean(where), (el) => el.child(div().min_w(0).truncate().child(where)))
      .when(g.ahead > 0, (el) => el.child(div().flex_none().text_color(t.ansi2).child(`\u2191${g.ahead}`)))
      .when(g.behind > 0, (el) => el.child(div().flex_none().text_color(t.ansi1).child(`\u2193${g.behind}`)));
  }

  row({ w, i, g, tree }, t, first) {
    const on = w.active;
    const colors = shared("space.colors") ?? {};
    const color = colors[w.id] ?? "ansi6";
    const fill = color.startsWith("#") ? color : (MARK[color] ?? t[color]);
    return v_flex()
      .relative()
      .id(`space-${w.id}`)
      .pl(PAD).pr(12)
      .mt(first ? 2 : 8)
      .h(ROW)
      .flex_none()
      .justify_center()
      .when(on, (el) => el.bg(t.selected))
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .when(this.pressed === i && this.over !== i, (el) => el.opacity(0.5))
      .when(this.pressed !== null && this.over === i && this.pressed !== i, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(this.pressed < i, line => line.bottom(0))
          .when(this.pressed > i, line => line.top(0)),
      ))
      .on_mouse_down("left", () => {
        this.pressed = i;
        this.over = i;
      })
      .on_mouse_move((_e, cx) => {
        const source = spaces()[this.pressed];
        const over = source && (source.machine ?? null) === (w.machine ?? null) ? i : null;
        if (this.pressed !== null && this.over !== over) {
          this.over = over;
          cx.notify();
        }
      })
      .on_mouse_up("left", (_e, cx) => {
        const from = this.pressed;
        const over = this.over;
        this.pressed = null;
        this.over = null;
        if (from !== null && over === i && from !== i) run("space.move", { id: spaces()[from].id, index: i + 1 });
        else if (from === i) run("space.select", { id: w.id });
        cx.notify();
      })
      .on_mouse_down("right", () => this.menu(w))
      .child(
        h_flex()
          .items_center()
          // The key is a margin note: same place on every row, never louder
          // than the name it labels.
          .child(div().w(KEY).flex_none().text_size(10.5).text_color(t.dim).child(mKey(i) ?? ""))
          .child(h_flex().flex_1().min_w(0).gap(8).items_center()
            .when(Boolean(tree), el => el.pl(NEST))
            .child(tree
              ? slot(svg("mods/workspace-chrome/branch.svg").size(12).text_color(t.dim))
              : slot(div().size(7).rounded(4).bg(fill)))
            .child(div().flex_shrink(0).max_w(150).truncate().text_size(12.5).font_semibold()
              .text_color(on ? t.foreground : t.muted).child(w.name))
            .child(g ? this.gitTail(g, tree, w.name, t) : div().flex_1())),
      );
  }

  agentRow(a, w, t, ps) {
    const tab = w.tabs?.find((x) => x.id === a.tab);
    const need = a.status === "blocked";
    const name = agentName(a, tab, ps);
    const ink = need ? PINE : t.dim;
    const ctx = (shared("claude.status")?.agents ?? {})[a.address]?.ctx;
    // How long it has been in this state, or the minute it finished.
    const when = a.status === "working" && tab?.working_since ? since(tab.working_since)
      : need && tab?.changed_at ? since(tab.changed_at)
      : a.status === "done" && tab?.changed_at ? clock(tab.changed_at)
      : null;
    // An unnamed tab is called after its folder, which is what its space is
    // called: printing that name under itself is the list's loudest noise. Say
    // it once, and give the agent one line for the session it is running. A
    // named tab ("fix login") earns the second line back, and then the session
    // name is worth a word only when it differs from that name.
    const bare = name === w.name;
    const session = sessionName(a);
    // A session called after its space was already said one line up, so the
    // time stands alone there; only a name that adds one is printed. With
    // neither to show, the state word steps back in rather than a mute row.
    const said = session === w.name || session === name;
    const lead = (said ? null : session)
      ?? (need ? "waiting for an answer" : null)
      ?? (when ? null : WORD[a.status]);
    const says = h_flex().flex_1().min_w(0).gap(5).items_center().text_size(11).text_color(ink)
      .when(Boolean(lead), (el) => el.child(div().min_w(0).truncate().font_semibold().child(lead)))
      .when(Boolean(when), (el) => el.child(div().flex_none().child(lead ? `· ${when}` : when)));
    return v_flex()
      .id(`agent-${a.address}`)
      .pl(PAD + KEY + NEST).pr(12).py(4).gap(1).flex_none()
      .when(need, (el) => el.bg(t.blocked))
      // `raised`, not `selected`: the space band owns that tone, and every
      // text colour still clears 4.5:1 on it in both themes.
      .when(!need && a.focused, (el) => el.bg(t.raised))
      .when(!need && !a.focused, (el) => el.hover((s) => s.bg(t.hover)))
      .on_click(() => run("agent.focus", { terminal: a.address }))
      .child(h_flex().gap(8).items_center()
        .child(marker(a.status, t, ink))
        .child(bare ? says : div().flex_1().min_w(0).truncate().text_color(need ? PINE : t.foreground).child(name))
        // Context left, red once under a fifth, as in the terminal's status line.
        .when(typeof ctx === "number", (el) => el.child(div().flex_none().text_size(10.5)
          .text_color(ctx < 20 && !need ? t.ansi1 : ink).child(`ctx ${Math.round(ctx)}%`))))
      .when(!bare, (el) => el.child(h_flex().pl(20).child(says)));
  }

  compact({ w, i }, t) {
    return h_flex()
      .id(`space-${w.id}`)
      .h(26)
      .flex_none()
      .justify_center()
      .gap(4)
      .when(w.active, (el) => el.bg(t.selected))
      .hover((s) => s.bg(t.hover))
      .on_click(() => run("space.select", { id: w.id }))
      .child(div().text_size(11).text_color(w.active ? t.foreground : t.dim).child(mKey(i) ?? String(i + 1)))
      .child(w.status === "blocked"
        ? div().size(7).rounded(4).bg(t.blocked)
        : marker(w.status, t, PINE));
  }

  render() {
    const t = theme();
    const collapsed = narrow();
    const palette = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
    const sp = spaces();
    const ids = new Set(sp.map(p => p.id));
    const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
    let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
    for (const p of sp) {
      if (kept[p.id] || p.name === "~") continue;
      const uses = c => Object.values(kept).filter(v => v === c).length;
      kept[p.id] = palette.reduce((best, c) => uses(c) < uses(best) ? c : best);
      changed = true;
    }
    if (changed) setShared("space.colors", kept);
    const rows = this.grouped(t, collapsed);
    // agent.next / agent.prev walk the agents in sidebar order (expanded only).
    if (!collapsed) setAgentOrder(this.order ?? []);
    return v_flex().size_full().min_h(0).bg(t.chrome).text_size(13)
      .child(h_flex().h(31).pl(PAD).pr(10).items_center().justify_between().text_size(11.5).text_color(t.dim)
        .when(!collapsed, el => el.child("Spaces"))
        .child(div().id("space-new").size(26).flex_none().flex().items_center().justify_center().rounded(6).hover(s => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => run("space.new")).child(svg("mods/workspace-chrome/plus.svg").size(14))))
      .child(v_flex().flex_1().min_h(0).pb(14).overflow_y_scrollbar().mode("always")
        .on_mouse_up("left", (_e, cx) => { this.pressed = null; cx.notify(); })
        .children(rows));
  }

}
