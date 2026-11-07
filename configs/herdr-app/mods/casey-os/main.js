// Casey OS: the Linear team COS as a board in the cockpit. A tab of its own, so
// it never competes with terminal text — but it reads like the sidebar does.
// Ochre (theme `blocked`) means "needs you" and nothing else, here as there: the
// two statuses that are Casey's own move (Needs me, In Review) are the only loud
// rows. `waiting` is parked on someone else, so it stays quiet with its age.
// Below that: what is moving, what is next. The gate queue is a count, not rows.
// Click any row to open it in Linear.
//
// The key: read from 1Password once per app start (`op read`), kept in memory
// only — never written, never logged, never put in an error message.
// Override the reference with the pane's `token` prop; `sample` prop reads a
// recorded GraphQL response from a file instead, to look at the board without a key.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { props, theme, settings, exec, readTextFile, notify, setShared, run } from "herdr";
import { MINE, lanes, gates, norm, since, teamUrl, needsYou, laneWord, committed } from "./lanes.js";

const PINE = "#283128"; // brand ink: text on the ochre fill
const TOKEN = "op://terminal access/linear COS key/credential";
const TEAM = "COS";
const EVERY = 120000; // Linear moves on human timescales; the panel lives in a background tab
const ACTIVE = ["triage", "backlog", "unstarted", "started"];
const LEDGER = 860; // below this the ledger folds into one line under the stream
const MEASURE = 620; // a task title is a sentence; it stops being readable past this

const QUERY = `query CaseyOS($team: String!, $types: [String!]) {
  issues(first: 100, orderBy: updatedAt,
         filter: { team: { key: { eq: $team } }, state: { type: { in: $types } } }) {
    nodes {
      id identifier title url updatedAt
      state { name type }
      labels { nodes { id name } }
      project { name }
    }
    pageInfo { hasNextPage }
  }
  issueLabels(first: 250) { nodes { id name parent { name } } }
  workflowStates(first: 150) { nodes { id name type team { key } } }
}`;

const CARD = `query CaseyOSCard($id: String!) {
  issue(id: $id) {
    description
    comments(first: 30) { nodes { id body createdAt user { displayName } } }
  }
}`;

const SET_STATE = `mutation CaseyOSState($id: String!, $stateId: String!) {
  issueUpdate(id: $id, input: { stateId: $stateId }) { success }
}`;

// issueUpdate replaces the whole label set, so the set is rebuilt from what
// Linear holds at the moment of the click, never from a board read up to two
// minutes old: otherwise a label changed in Linear meanwhile is silently lost.
const CURRENT = `query CaseyOSLabels($id: String!) {
  issue(id: $id) { labels { nodes { id } } }
}`;

const ASSIGN = `mutation CaseyOSAssign($id: String!, $labelIds: [String!]!) {
  issueUpdate(id: $id, input: { labelIds: $labelIds }) { success }
}`;

// The two single-select label groups the runner reads. Labelling a Candidate or
// Ready card from either one starts a Claude session within about a minute
// (bin/linear-runs.py), so these chips start work rather than tag it.
const GROUPS = [
  { parent: "claude model", label: "Model" },
  { parent: "claude effort", label: "Effort" },
];
const RUNS_FROM = ["Candidate", "Ready"];

// Every session started from a card runs on cc1, never on a laptop (Casey, 7 Nov 2026): cc1 is awake
// around the clock, so the work is not cut off when this machine sleeps, and the headless runner is
// there too. A space carries its machine (`hc machine ls`), so the space is cc1's while its station
// still stands in this bar; RUN_CWD is read on cc1, where the cards' repo lives.
const RUN_HOST = "cc1";
const RUN_CWD = "/Users/caseyromkes/dev/casey-os";

const ICON = (name) => `mods/workspace-chrome/${name}.svg`;

export default class CaseyOS extends View {
  init(_props, cx) {
    this.issues = null; // null until the first answer arrives
    this.error = null; // { what, fix }
    this.at = null; // when the list last came in
    this.more = false; // Linear had more than this board asked for
    this.width = Infinity;
    this.open = null; // { id, mode: "read" | "assign" }: the one card unfolded
    this.comments = {}; // identifier -> [] once read, "loading", or { error }
    this.descriptions = {}; // identifier -> the card's own text, for handing to a session
    this.groups = null; // the label vocabulary, from Linear rather than written down here
    this.closers = []; // the team's completed and canceled states, by type
    this.busy = null; // the card a label write is in flight for
    this.load(cx);
    cx.timer.every(EVERY, (cx) => this.load(cx));
  }

  // op's stdout *is* the secret: only its stderr ever reaches a message.
  async key() {
    if (this.token) return this.token;
    const ref = props()?.token ?? TOKEN;
    const r = await exec("op", ["read", ref]);
    const value = (r.stdout ?? "").trim();
    if (r.code !== 0 || !value) {
      const e = new Error((r.stderr ?? "").trim().split("\n")[0] || "1Password did not answer.");
      e.fix = `op read '${ref}'`;
      throw e;
    }
    this.token = value;
    return value;
  }

  async ask(query, variables) {
    const key = await this.key();
    const res = await fetch("https://api.linear.app/graphql", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: key },
      body: JSON.stringify({ query, variables }),
    });
    if (res.status === 401 || res.status === 403) {
      this.token = null; // a rotated key is read again on the next turn of the timer
      const e = new Error(`Linear refused the key (${res.status}).`);
      e.fix = `Check ${props()?.token ?? TOKEN} holds a current personal API key.`;
      throw e;
    }
    if (!res.ok) throw new Error(`Linear answered ${res.status}.`);
    const body = await res.json();
    if (body.errors?.length) throw new Error(body.errors[0]?.message ?? "Linear reported an error.");
    return body;
  }

  load(cx) {
    cx.spawn(async (cx) => {
      try {
        const body = props()?.sample
          ? JSON.parse((await readTextFile(props().sample)) ?? "null")
          : await this.ask(QUERY, { team: props()?.team ?? TEAM, types: ACTIVE });
        const list = body?.data?.issues;
        if (!list?.nodes) throw new Error("Linear sent no issues.");
        this.issues = list.nodes.map(norm);
        this.more = Boolean(list.pageInfo?.hasNextPage);
        // The chips are built from Linear's own vocabulary, so a renamed or
        // added model shows up here without this file changing.
        const all = body?.data?.issueLabels?.nodes ?? [];
        this.groups = GROUPS.map((g) => ({ ...g, options: all.filter((l) => l.parent?.name === g.parent) }))
          .filter((g) => g.options.length);
        // Done and Dropped by what they are, not by name: this team happens to
        // call them that, and the ids are never written down here.
        const team = props()?.team ?? TEAM;
        const states = (body?.data?.workflowStates?.nodes ?? []).filter((s) => s.team?.key === team);
        this.closers = [
          states.find((s) => s.type === "completed"),
          states.find((s) => s.type === "canceled"),
        ].filter(Boolean);
        this.error = null;
        this.at = Date.now();
      } catch (e) {
        this.error = { what: String(e?.message ?? e), fix: e?.fix ?? null };
      }
      this.publish();
      cx.notify();
    });
  }

  // The counts, for anything else that wants to say them — the tab switcher
  // puts them in this board's title. Written on each read, never on render.
  publish() {
    const l = this.issues ? lanes(this.issues) : null;
    setShared("casey-os", {
      mine: l?.mine.length ?? 0,
      doing: l?.doing.length ?? 0,
      ready: l?.ready.length ?? 0,
      waiting: l?.waiting.length ?? 0,
      gate: l?.gate.length ?? 0,
      open: this.issues?.length ?? 0,
      at: this.at,
      error: this.error?.what ?? null,
    });
  }

  openUrl(url, cx) {
    cx.spawn(async () => {
      try {
        await exec("open", [url]);
      } catch {
        notify({ title: "Couldn't open Linear", body: url, level: "warn" });
      }
    });
  }

  // Left click unfolds the discussion, right click the run chips. One card at a
  // time: the same gesture on an open card folds it again.
  toggle(i, mode, cx) {
    this.open = this.open?.id === i.id && this.open.mode === mode ? null : { id: i.id, mode };
    if (this.open?.mode === "read" && !this.comments[i.id]) this.loadComments(i, cx);
    cx.notify();
  }

  loadComments(i, cx) {
    this.comments[i.id] = "loading";
    cx.spawn(async (cx) => {
      try {
        if (props()?.sample) {
          const s = JSON.parse((await readTextFile(props().sample)) ?? "null");
          this.comments[i.id] = s?.data?.comments?.[i.id]?.nodes ?? [];
          this.descriptions[i.id] = s?.data?.descriptions?.[i.id] ?? null;
        } else {
          const got = (await this.ask(CARD, { id: i.uuid ?? i.id }))?.data?.issue;
          this.comments[i.id] = got?.comments?.nodes ?? [];
          this.descriptions[i.id] = got?.description ?? null;
        }
      } catch (e) {
        this.comments[i.id] = { error: String(e?.message ?? e) };
      }
      cx.notify();
    });
  }

  // Done or Dropped from the card you just read. Both are reversible in Linear,
  // so a click is enough; the row leaves the board on the next read.
  close(i, state, cx) {
    if (props()?.sample) return;
    this.busy = i.id;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        await this.ask(SET_STATE, { id: i.uuid, stateId: state.id });
        this.open = null;
      } catch (e) {
        notify({ title: `Couldn't set ${i.id} to ${state.name}`, body: String(e?.message ?? e), level: "warn" });
      }
      this.busy = null;
      this.load(cx);
    });
  }

  // Neither finished nor handed to a headless run: a session of its own, with
  // the card already in front of it. Its space is RUN_HOST's, like every other
  // session a card starts, and stands in the bar as a station beside the board
  // rather than renaming the board's.
  talk(i, cx) {
    const head = [i.status, i.gate, i.project, i.at ? `updated ${since(i.at)} ago` : null].filter(Boolean).join(" · ");
    const comments = Array.isArray(this.comments[i.id]) ? this.comments[i.id] : [];
    const task = [
      `Let's talk about ${i.id}.`,
      "",
      i.title,
      head,
      i.url,
      this.descriptions[i.id] ? `\n--- description ---\n${this.descriptions[i.id]}` : null,
      comments.length
        ? `\n--- discussion ---\n${comments.map((c) => `${c.user?.displayName ?? "someone"}:\n${c.body ?? ""}`).join("\n\n")}`
        : null,
      "\nI have read this on the Casey OS board and want to think it through with you, not hand it to a run.",
    ].filter((x) => x !== null).join("\n");
    this.open = null;
    cx.notify();
    run("space.new", { name: i.id, machine: RUN_HOST, folder: RUN_CWD, argv: ["claude"], task });
  }

  // Both groups are single-select in Linear, so the chosen label replaces its
  // sibling: drop every option of that group, then add the one picked.
  assignLabel(i, group, option, cx) {
    if (props()?.sample) return; // a preview must not write to the real workspace
    this.busy = i.id;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const held = (await this.ask(CURRENT, { id: i.uuid }))?.data?.issue?.labels?.nodes ?? [];
        const drop = new Set(group.options.map((o) => o.id));
        const next = [...held.map((l) => l.id).filter((id) => !drop.has(id)), option.id];
        await this.ask(ASSIGN, { id: i.uuid, labelIds: next });
      } catch (e) {
        notify({ title: `Couldn't label ${i.id}`, body: String(e?.message ?? e), level: "warn" });
      }
      this.busy = null;
      this.load(cx);
    });
  }

  mono() {
    return settings().font ?? "JetBrains Mono";
  }

  // A label, its count, and a rule to the edge: structure without boxes.
  head(label, count, t) {
    return h_flex()
      .h(18)
      .flex_none()
      .gap(8)
      .items_center()
      .text_size(11.5)
      .text_color(t.dim)
      .child(div().flex_none().child(label))
      .when(count !== null, (el) => el.child(div().flex_none().child(String(count))))
      .child(div().flex_1().h(1).bg(t.border));
  }

  section(label, count, children, t) {
    return v_flex().flex_none().gap(6).child(this.head(label, count, t)).children(children);
  }

  // The loud row: ochre fill, pine ink, the whole sentence, and why it is here.
  // It stops at the measure rather than running the width of the board: a slab
  // of ochre reaching past its own words reads as a banner, not as a task.
  loud(i, t) {
    // A card lifted here by its gate still says where it otherwise sits, so the
    // band never hides that the work is already moving.
    const why = [needsYou(i), MINE[i.status] ? null : laneWord(i), i.risk ? "high risk" : null, i.project]
      .filter(Boolean).join(" · ");
    return v_flex()
      .id(`mine-${i.id}`)
      .flex_none()
      .max_w(MEASURE + 190)
      .px(12)
      .py(8)
      .gap(3)
      .rounded(8)
      .bg(t.blocked)
      .border(1)
      .border_color(t.blocked)
      .hover((s) => s.border_color(PINE))
      .cursor_pointer()
      .tooltip(`${i.id}: click to read it, right-click to run it`)
      .on_click((_e, cx) => this.toggle(i, "read", cx))
      .on_mouse_down("right", (_e, cx) => this.toggle(i, "assign", cx))
      .child(
        h_flex()
          .gap(10)
          // Not baseline: a title that wraps to two lines drags a baselined
          // identifier down to the second one. pt(2) sits it on the first line.
          .items_start()
          .child(div().flex_none().pt(2).font_family(this.mono()).text_size(11.5).font_semibold().text_color(PINE).child(i.id))
          .child(div().flex_1().min_w(0).child(div().max_w(MEASURE).text_size(13.5).text_color(PINE).child(i.title)))
          .when(Boolean(i.at), (el) => el.child(div().flex_none().pt(2).text_size(11.5).text_color(PINE).child(since(i.at)))),
      )
      .child(div().text_size(12).text_color(PINE).child(why));
  }

  // The quiet row: one line, the mark saying which lane it is in.
  quiet(i, mark, t) {
    const tail = [i.project, i.at ? since(i.at) : null].filter(Boolean).join(" · ");
    return h_flex()
      .id(`row-${i.id}`)
      .h(28)
      .flex_none()
      .px(12)
      .gap(10)
      .items_center()
      .rounded(7)
      .hover((s) => s.bg(t.hover))
      .cursor_pointer()
      .tooltip(`${i.id}: click to read it, right-click to run it`)
      .on_click((_e, cx) => this.toggle(i, "read", cx))
      .on_mouse_down("right", (_e, cx) => this.toggle(i, "assign", cx))
      .when(this.open?.id === i.id, (el) => el.bg(t.selected))
      .child(h_flex().size(12).flex_none().items_center().justify_center().child(mark))
      .child(div().flex_none().font_family(this.mono()).text_size(11.5).text_color(t.dim).child(i.id))
      .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(i.title))
      .when(Boolean(tail), (el) => el.child(div().flex_none().max_w(220).truncate().text_size(11.5).text_color(t.dim).child(tail)));
  }

  // A row plus whatever it has unfolded, indented under it against a hairline.
  card(i, row, t) {
    if (this.open?.id !== i.id) return row;
    const panel = this.open.mode === "assign" ? this.assign(i, t) : this.read(i, t);
    return v_flex()
      .flex_none()
      .gap(8)
      .child(row)
      .child(v_flex().flex_none().ml(12).pl(14).pb(4).gap(8).border_l(1).border_color(t.border).child(panel));
  }

  // The discussion, in place. The intake card's whole ask lives down here.
  read(i, t) {
    const got = this.comments[i.id];
    if (got === "loading") {
      return h_flex().h(22).flex_none().gap(8).items_center().text_size(12).text_color(t.dim)
        .child(svg(ICON("spinner")).size(12).flex_none().spin(900)).child("Reading the discussion…");
    }
    // What you do once you have read it: leave, end it, or sit down with it.
    // `writes` says whether it needs the Linear key. Talking does not — it opens
    // a session on RUN_HOST — so a snapshot board still does it. One that
    // does need the key goes grey and says why, rather than looking alive and
    // swallowing the click.
    const action = (key, label, ink, writes, go) => {
      const dead = writes && Boolean(props()?.sample);
      return h_flex().id(`${key}-${i.id}`).h(22).flex_none().px(8).items_center().rounded(6)
        .text_size(12).text_color(dead ? t.idle : ink)
        .when(dead, (el) => el.tooltip(`This board is reading a snapshot. Add the Linear key and ${label} works.`))
        .when(!dead, (el) => el
          .cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(go))
        .child(label);
    };
    const link = h_flex().flex_none().gap(10).items_center().pt(2)
      .child(
        h_flex().id(`linear-${i.id}`).h(22).flex_none().px(8).gap(2).items_center().rounded(6)
          .text_size(12).text_color(t.muted).hover((s) => s.bg(t.hover).text_color(t.foreground)).cursor_pointer()
          .on_click((_e, cx) => this.openUrl(i.url, cx))
          .child(div().child("Open in Linear")).child(svg(ICON("chevron-right")).size(12).flex_none()),
      )
      .children(this.closers.map((s) =>
        action(`close-${s.type}`, s.name, t.muted, true, (_e, cx) => this.close(i, s, cx))))
      .child(action("talk", "Let's talk about this", t.accent, false, (_e, cx) => this.talk(i, cx)))
      .when(this.busy === i.id, (el) => el.child(svg(ICON("spinner")).size(12).flex_none().spin(900)))
      .when(Boolean(props()?.sample), (el) => el.child(
        div().flex_none().text_size(11.5).text_color(t.dim).child("snapshot — the greyed ones need the key"),
      ));
    if (got?.error) {
      return v_flex().flex_none().gap(4).items_start()
        .child(div().text_size(12).text_color(t.ansi1).child(got.error)).child(link);
    }
    if (!got?.length) {
      return v_flex().flex_none().gap(4).items_start()
        .child(div().text_size(12).text_color(t.muted).child("No comments on this one.")).child(link);
    }
    return v_flex().flex_none().gap(10).items_start().max_w(MEASURE)
      .children(got.map((c) =>
        v_flex().flex_none().gap(2)
          .child(h_flex().gap(8).items_baseline().text_size(11.5).text_color(t.dim)
            .child(div().flex_none().child(c.user?.displayName ?? "someone"))
            .child(div().flex_none().child(since(Date.parse(c.createdAt ?? "") || Date.now()))))
          .child(TextView.markdown(`c-${c.id}`, c.body ?? ""))))
      .child(link);
  }

  // Right-click: hand the card to a model. These chips are not tags — on a
  // Candidate or Ready card the runner picks the label up within about a minute
  // and a session starts, so the panel says so before it says anything else.
  assign(i, t) {
    const runs = RUNS_FROM.includes(i.status);
    if (!this.groups?.length) {
      return div().text_size(12).text_color(t.muted).child("Running a card needs the Linear key.");
    }
    const dead = Boolean(props()?.sample); // a chip writes, so a snapshot cannot offer it
    const chip = (group, o) => {
      const on = i.labels.includes(o.name);
      return h_flex().id(`set-${i.id}-${o.id}`).h(22).flex_none().px(9).items_center().rounded(6)
        .border(1).border_color(on ? t.accent : t.border)
        .text_size(12).text_color(dead && !on ? t.idle : on ? t.foreground : t.muted)
        .when(on, (el) => el.bg(t.selected))
        .when(dead, (el) => el.tooltip("This board is reading a snapshot. Add the Linear key to run a card."))
        .when(!dead, (el) => el
          .cursor_pointer()
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click((_e, cx) => this.assignLabel(i, group, o, cx)))
        .child(o.name);
    };
    return v_flex().flex_none().gap(8).items_start()
      .child(div().text_size(11.5).text_color(runs ? t.blocked : t.dim).child(
        runs ? `Starts a session on ${i.id} within about a minute.`
          : `Labels only: runs start from ${RUNS_FROM.join(" or ")}, and this is ${i.status}.`,
      ))
      // A preview still says what it would do; it just does not do it.
      .when(Boolean(props()?.sample), (el) => el.child(
        div().text_size(11.5).text_color(t.dim).child("Preview — this board writes nothing."),
      ))
      .children(this.groups.map((g) =>
        h_flex().flex_none().gap(8).items_center()
          .child(div().flex_none().w(44).text_size(11.5).text_color(t.dim).child(g.label))
          .child(h_flex().flex_none().gap(6).children(g.options.map((o) => chip(g, o))))))
      .when(this.busy === i.id, (el) => el.child(
        h_flex().h(20).flex_none().gap(8).items_center().text_size(11.5).text_color(t.dim)
          .child(svg(ICON("spinner")).size(12).flex_none().spin(900)).child("Saving…")));
  }

  // Factories, not elements: a GPUI element is single-use, so every row builds
  // its own mark.
  marks(t) {
    return {
      doing: () => svg(ICON("spinner")).size(12).flex_none().text_color(t.working).spin(900),
      ready: () => div().size(7).rounded_full().flex_none().border(1).border_color(t.idle),
      waiting: () => svg(ICON("clock")).size(12).flex_none().text_color(t.idle),
    };
  }

  stream(l, t) {
    const mark = this.marks(t);
    const out = [];
    out.push(
      this.section(
        "Needs you",
        l.mine.length,
        l.mine.length
          ? l.mine.map((i) => this.card(i, this.loud(i, t), t))
          : [div().flex_none().px(12).py(6).text_color(t.muted).child("Nothing waiting on you.")],
        t,
      ),
    );
    const rows = (list, m) => list.map((i) => this.card(i, this.quiet(i, m(), t), t));
    if (l.doing.length) out.push(this.section("Moving", l.doing.length, rows(l.doing, mark.doing), t));
    if (l.ready.length) out.push(this.section("Ready", l.ready.length, rows(l.ready, mark.ready), t));
    if (l.waiting.length) out.push(this.section("Waiting on someone else", l.waiting.length, rows(l.waiting, mark.waiting), t));
    return out;
  }

  ledger(l, t) {
    const { groups, parked } = gates(l.gate);
    const risky = (this.issues ?? []).filter((i) => i.risk && !MINE[i.status]);
    const line = (left, right) =>
      h_flex()
        .h(22)
        .flex_none()
        .gap(8)
        .items_center()
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.muted).child(left))
        .child(div().flex_none().text_size(12).text_color(t.dim).child(right));
    const out = [];
    if (groups.length)
      out.push(
        this.section(
          "Gate queue",
          l.gate.length,
          [
            ...groups.map((g) => line(g.words, String(g.count))),
            // A second axis over the same rows, so it is a sentence, not a group
            // whose count would refuse to add up with the others.
            ...(parked ? [div().flex_none().pt(2).text_size(11.5).text_color(t.dim).child(`${parked} of these wait on someone else`)] : []),
          ],
          t,
        ),
      );
    if (risky.length)
      out.push(
        this.section(
          "High risk",
          risky.length,
          risky.map((i) =>
            h_flex()
              .id(`risk-${i.id}`)
              .h(22)
              .flex_none()
              .gap(8)
              .items_center()
              .rounded(6)
              .hover((s) => s.bg(t.hover))
              .cursor_pointer()
              .tooltip(`Open ${i.id} in Linear`)
              .on_click((_e, cx) => this.openUrl(i.url, cx))
              .child(div().flex_none().font_family(this.mono()).text_size(11.5).text_color(t.dim).child(i.id))
              .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.muted).child(i.title)),
          ),
          t,
        ),
      );
    return out;
  }

  // The board has no title bar of its own: Herdr draws the pane's, and the first
  // thing worth reading is the first row. What a header would have carried —
  // how many, how fresh, the way out — sits here instead.
  foot(t) {
    const url = teamUrl(this.issues ?? [], props()?.team ?? TEAM);
    const open = this.issues?.length ?? 0;
    return v_flex()
      .flex_none()
      .gap(1)
      .child(div().flex_none().text_size(11.5).text_color(t.dim).child(`${open} open${this.more ? " · first 100" : ""}`))
      .child(
        h_flex()
          .id("refresh")
          .h(22)
          .flex_none()
          .gap(6)
          .items_center()
          .text_size(11.5)
          .text_color(t.dim)
          .hover((s) => s.text_color(t.foreground))
          .cursor_pointer()
          .tooltip("Read Linear again")
          .on_click((_e, cx) => this.load(cx))
          .child(svg(ICON("clock")).size(12).flex_none())
          .child(this.at ? `read ${since(this.at)} ago` : "not read yet"),
      )
      .when(Boolean(url), (el) =>
        el.child(
          h_flex()
            .id("open-linear")
            .h(22)
            .flex_none()
            .gap(2)
            .items_center()
            .text_size(12)
            .text_color(t.muted)
            .hover((s) => s.text_color(t.foreground))
            .cursor_pointer()
            .on_click((_e, cx) => this.openUrl(url, cx))
            .child(div().child("All of Casey OS"))
            .child(svg(ICON("chevron-right")).size(12).flex_none()),
        ),
      );
  }

  // Nothing read yet: the sidebar's own idiom, one line and the shipped spinner.
  waitingRow(t) {
    return h_flex()
      .h(28)
      .flex_none()
      .gap(8)
      .items_center()
      .text_size(12)
      .text_color(t.dim)
      .child(svg(ICON("spinner")).size(12).flex_none().spin(900))
      .child("Reading Linear…");
  }

  errorRow(t) {
    return v_flex()
      .flex_none()
      .gap(4)
      // Without this the button stretches the width of the pane.
      .items_start()
      .max_w(MEASURE)
      .child(div().text_color(t.ansi1).child(this.error.what))
      .when(Boolean(this.error.fix), (el) =>
        el.child(div().text_size(12).text_color(t.muted).child("Put a Linear personal API key here, then this board fills itself:")).child(
          div().font_family(this.mono()).text_size(12).text_color(t.foreground).child(this.error.fix),
        ),
      )
      .child(
        h_flex()
          .id("retry")
          .h(24)
          .mt(2)
          .flex_none()
          .px(8)
          .items_center()
          .rounded(6)
          .border(1)
          .border_color(t.border)
          .text_size(12)
          .text_color(t.muted)
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .cursor_pointer()
          .on_click((_e, cx) => this.load(cx))
          .child("Try again"),
      );
  }

  render(cx) {
    const t = theme();
    const l = this.issues ? lanes(this.issues) : null;
    const wide = this.width >= LEDGER;
    const ledger = l && wide ? this.ledger(l, t) : [];
    const body = !this.issues
      ? [this.error ? this.errorRow(t) : this.waitingRow(t)]
      : [
          ...this.stream(l, t),
          // Folded ledger: the gate queue still gets said, in one line, and the
          // footer follows the stream instead of the column that is gone.
          ...(wide
            ? []
            : [
                ...(l.gate.length
                  ? [div().flex_none().text_size(11.5).text_color(t.dim).child(`${l.gate.length} in the gate queue · ${gates(l.gate).groups.map((g) => `${g.count} ${g.words}`).join(" · ")}`)]
                  : []),
                this.foot(t),
              ]),
        ];
    return v_flex()
      .id("root")
      .size_full()
      .min_h(0)
      .bg(t.background)
      .text_size(13)
      .on_size_change((size, cx) => {
        if (size.width === this.width) return;
        this.width = size.width;
        cx.notify();
      })
      .child(
        h_flex()
          .flex_1()
          .min_h(0)
          // pt clears the pane header Herdr floats over this mod on hover (30px
          // in the cockpit layout): at 16 the first section label reads fine
          // until the pointer arrives, which is exactly when it is being read.
          .child(v_flex().flex_1().min_w(0).px(16).pt(34).pb(16).gap(20).overflow_y_scrollbar().mode("always").children(body))
          .when(ledger.length > 0 || (l && wide), (el) =>
            el.child(
              v_flex()
                .w(272)
                .flex_none()
                .min_h(0)
                .px(16)
                .pt(34)
                .pb(16)
                .gap(20)
                .border_l(1)
                .border_color(t.border)
                .overflow_y_scrollbar()
                .mode("always")
                .children(ledger)
                .child(div().flex_1().min_h(8))
                .child(this.foot(t)),
            ),
          ),
      );
  }
}
